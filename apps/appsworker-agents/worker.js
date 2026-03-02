require('dotenv').config();
const redis = require('redis');
const axios = require('axios');

// Configuration
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama3';
const WORKER_ID = process.env.WORKER_ID || 'worker-1';
const NODE_ENV = process.env.NODE_ENV || 'development';

// Initialize Redis client
const client = redis.createClient({ url: REDIS_URL });

client.on('error', (err) => {
  console.error('[REDIS ERROR]', err);
  process.exit(1);
});

client.on('connect', () => {
  console.log('[REDIS] Connected successfully');
});

// Error handler for uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('[UNCAUGHT EXCEPTION]', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('[WORKER] Shutting down gracefully...');
  await client.quit();
  process.exit(0);
});

/**
 * Process AI jobs from Redis queue
 */
async function processJob(job) {
  try {
    console.log(`[JOB-${job.id}] Processing: ${job.type}`);
    
    switch (job.type) {
      case 'llm_inference':
        return await handleLLMInference(job);
      case 'rag_embedding':
        return await handleRAGEmbedding(job);
      case 'text_analysis':
        return await handleTextAnalysis(job);
      default:
        throw new Error(`Unknown job type: ${job.type}`);
    }
  } catch (error) {
    console.error(`[JOB-${job.id}] Error:`, error);
    
    // Store failed job
    await client.lPush('failed-jobs', JSON.stringify({
      ...job,
      error: error.message,
      failedAt: new Date().toISOString()
    }));
    
    throw error;
  }
}

/**
 * Handle LLM inference requests
 */
async function handleLLMInference(job) {
  try {
    const { prompt, maxTokens = 500 } = job.payload;
    
    if (!prompt) {
      throw new Error('Prompt is required');
    }
    
    console.log(`[LLM] Inference request: ${prompt.substring(0, 50)}...`);
    
    const response = await axios.post(`${OLLAMA_URL}/api/generate`, {
      model: OLLAMA_MODEL,
      prompt: prompt,
      stream: false,
      num_predict: maxTokens
    }, { timeout: 30000 });
    
    return {
      jobId: job.id,
      type: job.type,
      result: response.data.response,
      model: OLLAMA_MODEL,
      completedAt: new Date().toISOString()
    };
  } catch (error) {
    throw new Error(`LLM inference failed: ${error.message}`);
  }
}

/**
 * Handle RAG embedding requests
 */
async function handleRAGEmbedding(job) {
  try {
    const { filePath, fileName } = job.payload;
    
    if (!filePath || !fileName) {
      throw new Error('FilePath and fileName are required');
    }
    
    console.log(`[RAG] Processing file: ${fileName}`);
    
    // In production, integrate with actual vector DB
    // For now, simulate embedding process
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return {
      jobId: job.id,
      type: job.type,
      result: {
        fileName: fileName,
        status: 'embedded',
        vectorCount: 1000,
        dimensions: 384
      },
      completedAt: new Date().toISOString()
    };
  } catch (error) {
    throw new Error(`RAG embedding failed: ${error.message}`);
  }
}

/**
 * Handle text analysis requests
 */
async function handleTextAnalysis(job) {
  try {
    const { text, analysisType = 'sentiment' } = job.payload;
    
    if (!text) {
      throw new Error('Text is required');
    }
    
    console.log(`[ANALYSIS] ${analysisType} analysis`);
    
    // Placeholder for actual analysis logic
    return {
      jobId: job.id,
      type: job.type,
      result: {
        analysisType: analysisType,
        textLength: text.length,
        status: 'completed'
      },
      completedAt: new Date().toISOString()
    };
  } catch (error) {
    throw new Error(`Text analysis failed: ${error.message}`);
  }
}

/**
 * Main worker loop
 */
async function startWorker() {
  try {
    await client.connect();
    
    console.log(`
╔═══════════════════════════════════════════════════════╗
║      imprompt generator Worker Agent Started 🤖        ║
╠═══════════════════════════════════════════════════════╣
║ Worker ID:    ${WORKER_ID.padEnd(47)}║
║ Environment:  ${NODE_ENV.padEnd(47)}║
║ Redis URL:    ${REDIS_URL.padEnd(47)}║
║ Ollama URL:   ${OLLAMA_URL.padEnd(47)}║
║ Model:        ${OLLAMA_MODEL.padEnd(47)}║
╚═══════════════════════════════════════════════════════╝
    `);
    
    // Main processing loop
    while (true) {
      try {
        // Check for jobs in queue
        const jobData = await client.rPop('job-queue');
        
        if (jobData) {
          const job = JSON.parse(jobData);
          const result = await processJob(job);
          
          // Store result
          await client.lPush('job-results', JSON.stringify(result));
          console.log(`[JOB-${job.id}] Completed successfully`);
        } else {
          // No jobs available, wait before checking again
          await new Promise(resolve => setTimeout(resolve, 5000));
          console.log(`[WORKER] Waiting for jobs... (${new Date().toISOString()})`);
        }
      } catch (error) {
        console.error('[WORKER LOOP ERROR]', error);
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, 10000));
      }
    }
  } catch (error) {
    console.error('[WORKER STARTUP ERROR]', error);
    process.exit(1);
  }
}

// Start the worker
startWorker().catch((error) => {
  console.error('[FATAL ERROR]', error);
  process.exit(1);
});