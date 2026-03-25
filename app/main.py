"""
Lightweight API Application for Active-Active Distributed System
Handles POST/PUT requests with Kafka buffering and Redis caching
"""

import os
import json
import uuid
import logging
from datetime import datetime
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import redis.asyncio as redis
from aiokafka import AIOKafkaProducer
import asyncpg

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="DOCMP API",
    description="Active-Active Distributed System API",
    version="1.0.0"
)

# Configuration from environment variables
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_AUTH_TOKEN = os.getenv("REDIS_AUTH_TOKEN", "")

KAFKA_BROKERS = os.getenv("KAFKA_BROKERS", "localhost:9092").split(",")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "docmp-updates")

DB_PRIMARY_HOST = os.getenv("DB_PRIMARY_HOST", "localhost")
DB_SECONDARY_HOST = os.getenv("DB_SECONDARY_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "docmp")
DB_USERNAME = os.getenv("DB_USERNAME", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

# Global connections
redis_client: Optional[redis.Redis] = None
kafka_producer: Optional[AIOKafkaProducer] = None
db_pool: Optional[asyncpg.Pool] = None


# Pydantic models
class UpdateRequest(BaseModel):
    entity_type: str = Field(..., description="Type of entity (e.g., user, order)")
    entity_id: str = Field(..., description="ID of the entity")
    operation: str = Field(..., description="Operation type: CREATE, UPDATE, DELETE")
    payload: Dict[str, Any] = Field(..., description="Data payload")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Optional metadata")


class UpdateResponse(BaseModel):
    transaction_id: str
    status: str
    message: str
    timestamp: str


@app.on_event("startup")
async def startup_event():
    """Initialize connections on startup"""
    global redis_client, kafka_producer, db_pool
    
    try:
        # Initialize Redis connection
        redis_client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_AUTH_TOKEN if REDIS_AUTH_TOKEN else None,
            decode_responses=True,
            socket_connect_timeout=5
        )
        await redis_client.ping()
        logger.info("Redis connection established")
    except Exception as e:
        logger.warning(f"Redis connection failed: {e}. Will use database fallback.")
        redis_client = None
    
    try:
        # Initialize Kafka producer
        kafka_producer = AIOKafkaProducer(
            bootstrap_servers=KAFKA_BROKERS,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            compression_type='snappy',
            acks='all',
            retries=3
        )
        await kafka_producer.start()
        logger.info("Kafka producer initialized")
    except Exception as e:
        logger.error(f"Kafka producer initialization failed: {e}")
        raise
    
    try:
        # Initialize database connection pool
        db_pool = await asyncpg.create_pool(
            host=DB_PRIMARY_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USERNAME,
            password=DB_PASSWORD,
            min_size=2,
            max_size=10
        )
        logger.info("Database connection pool established")
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup connections on shutdown"""
    global redis_client, kafka_producer, db_pool
    
    if redis_client:
        await redis_client.close()
        logger.info("Redis connection closed")
    
    if kafka_producer:
        await kafka_producer.stop()
        logger.info("Kafka producer stopped")
    
    if db_pool:
        await db_pool.close()
        logger.info("Database connection pool closed")


@app.get("/health")
async def health_check():
    """Health check endpoint for ALB"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {
            "redis": "unknown",
            "kafka": "unknown",
            "database": "unknown"
        }
    }
    
    # Check Redis
    try:
        if redis_client:
            await redis_client.ping()
            health_status["services"]["redis"] = "healthy"
    except Exception:
        health_status["services"]["redis"] = "unhealthy"
    
    # Check Kafka
    if kafka_producer and not kafka_producer._closed:
        health_status["services"]["kafka"] = "healthy"
    else:
        health_status["services"]["kafka"] = "unhealthy"
    
    # Check Database
    try:
        if db_pool:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            health_status["services"]["database"] = "healthy"
    except Exception:
        health_status["services"]["database"] = "unhealthy"
    
    return health_status


@app.post("/api/update", response_model=UpdateResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_update(request: UpdateRequest):
    """
    POST endpoint: Create or update an entity
    Immediately buffers to Kafka and updates Redis cache
    """
    return await process_update(request, "POST")


@app.put("/api/update/{entity_id}", response_model=UpdateResponse, status_code=status.HTTP_202_ACCEPTED)
async def update_entity(entity_id: str, request: UpdateRequest):
    """
    PUT endpoint: Update an existing entity
    Immediately buffers to Kafka and updates Redis cache
    """
    request.entity_id = entity_id
    return await process_update(request, "PUT")


async def process_update(request: UpdateRequest, method: str) -> UpdateResponse:
    """
    Core logic for processing updates:
    1. Generate transaction ID
    2. Send to Kafka (system memory)
    3. Update Redis cache (if available)
    4. Record in pending_updates table (if Redis unavailable)
    """
    transaction_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()
    
    # Prepare message for Kafka
    kafka_message = {
        "transaction_id": transaction_id,
        "entity_type": request.entity_type,
        "entity_id": request.entity_id,
        "operation": request.operation,
        "payload": request.payload,
        "metadata": request.metadata or {},
        "timestamp": timestamp,
        "method": method
    }
    
    try:
        # 1. Send to Kafka (primary system memory)
        kafka_metadata = await kafka_producer.send_and_wait(
            KAFKA_TOPIC,
            value=kafka_message,
            key=request.entity_id.encode('utf-8')
        )
        logger.info(f"Message sent to Kafka: {transaction_id}, partition: {kafka_metadata.partition}, offset: {kafka_metadata.offset}")
        
        # 2. Update Redis cache for immediate visibility
        redis_updated = False
        if redis_client:
            try:
                cache_key = f"{request.entity_type}:{request.entity_id}"
                await redis_client.setex(
                    cache_key,
                    3600,  # 1 hour TTL
                    json.dumps({
                        "transaction_id": transaction_id,
                        "data": request.payload,
                        "timestamp": timestamp,
                        "status": "pending"
                    })
                )
                redis_updated = True
                logger.info(f"Redis cache updated for {cache_key}")
            except Exception as e:
                logger.warning(f"Redis update failed: {e}. Using database fallback.")
        
        # 3. If Redis unavailable, record in pending_updates table
        if not redis_updated and db_pool:
            try:
                async with db_pool.acquire() as conn:
                    await conn.execute("""
                        INSERT INTO pending_updates (
                            transaction_id, entity_type, entity_id, operation,
                            payload, kafka_topic, kafka_partition, kafka_offset, metadata
                        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                    """, transaction_id, request.entity_type, request.entity_id,
                        request.operation, json.dumps(request.payload), KAFKA_TOPIC,
                        kafka_metadata.partition, kafka_metadata.offset,
                        json.dumps(request.metadata or {}))
                logger.info(f"Pending update recorded in database: {transaction_id}")
            except Exception as e:
                logger.error(f"Failed to record pending update: {e}")
        
        return UpdateResponse(
            transaction_id=transaction_id,
            status="accepted",
            message="Update buffered successfully",
            timestamp=timestamp
        )
        
    except Exception as e:
        logger.error(f"Failed to process update: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process update: {str(e)}"
        )


@app.get("/api/entity/{entity_type}/{entity_id}")
async def get_entity(entity_type: str, entity_id: str):
    """
    GET endpoint: Retrieve entity data
    Checks Redis first, then pending_updates table, then main database
    """
    cache_key = f"{entity_type}:{entity_id}"
    
    # 1. Try Redis cache first (fastest)
    if redis_client:
        try:
            cached_data = await redis_client.get(cache_key)
            if cached_data:
                logger.info(f"Cache hit for {cache_key}")
                return JSONResponse(
                    content=json.loads(cached_data),
                    headers={"X-Cache": "HIT"}
                )
        except Exception as e:
            logger.warning(f"Redis read failed: {e}")
    
    # 2. Check pending_updates table for in-flight transactions
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                pending = await conn.fetchrow("""
                    SELECT transaction_id, payload, created_at, status
                    FROM pending_updates
                    WHERE entity_type = $1 AND entity_id = $2
                    AND status IN ('PENDING', 'PROCESSING')
                    ORDER BY created_at DESC
                    LIMIT 1
                """, entity_type, entity_id)
                
                if pending:
                    return JSONResponse(
                        content={
                            "transaction_id": str(pending['transaction_id']),
                            "data": json.loads(pending['payload']),
                            "timestamp": pending['created_at'].isoformat(),
                            "status": pending['status']
                        },
                        headers={"X-Source": "PENDING"}
                    )
                
                # 3. Query main database
                # TODO: Implement main entity table query
                # For now, return not found
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Entity not found: {entity_type}/{entity_id}"
                )
                
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Database query failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Database query failed"
            )
    
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="All data sources unavailable"
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

# Made with Bob
