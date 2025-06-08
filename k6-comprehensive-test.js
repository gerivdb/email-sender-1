import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Custom metrics
const errorRate = new Rate('errors');

// Load test configuration
export const options = {
  scenarios: {
    comprehensive: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '300s', target: 1000 },
        { duration: '2h', target: 1000 },
        { duration: '2m', target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    http_reqs: ['rate>1000'],
    errors: ['rate<0.01'],
  },
  ext: {
    loadimpact: {
      distribution: {
        'amazon:us:ashburn': { loadZone: 'amazon:us:ashburn', percent: 30 },
        'amazon:us:oregon': { loadZone: 'amazon:us:oregon', percent: 20 },
        'amazon:ie:dublin': { loadZone: 'amazon:ie:dublin', percent: 20 },
        'amazon:sg:singapore': { loadZone: 'amazon:sg:singapore', percent: 15 },
        'amazon:au:sydney': { loadZone: 'amazon:au:sydney', percent: 10 },
        'amazon:br:sao-paulo': { loadZone: 'amazon:br:sao-paulo', percent: 5 },
      },
    },
  },
};

// Test data
const endpoints = [
  'https://branching-framework.com/api/v1/branches',
  'https://branching-framework.com/api/v1/sessions',
  'https://branching-framework.com/api/v1/contexts',
  'https://branching-framework.com/api/v1/events',
  'https://branching-framework.com/api/v1/analytics',
  'https://branching-framework.com/api/v1/ai/predictions',
  'https://branching-framework.com/api/v1/optimization',
  'https://branching-framework.com/api/v1/health'
];

const payloads = {
  createBranch: {
    name: 'test-branch-' + Math.random().toString(36).substr(2, 9),
    type: 'feature',
    metadata: {
      priority: Math.floor(Math.random() * 5) + 1,
      tags: ['loadtest', 'performance'],
      timestamp: new Date().toISOString()
    }
  },
  createSession: {
    user_id: 'user-' + Math.random().toString(36).substr(2, 9),
    session_type: 'interactive',
    capabilities: ['micro-sessions', 'event-driven', 'ai-optimization']
  },
  createEvent: {
    type: 'user_action',
    data: {
      action: 'branch_creation',
      metadata: { loadtest: true }
    },
    timestamp: new Date().toISOString()
  }
};

// Main test function
export default function() {
  const baseUrl = __ENV.BASE_URL || 'https://branching-framework.com';
  
  // Health check
  let healthResponse = http.get(\/health);
  check(healthResponse, {
    'health check status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Create branch (Level 1-3 operations)
  let branchResponse = http.post(
    \/api/v1/branches,
    JSON.stringify(payloads.createBranch),
    {
      headers: {
        'Content-Type': 'application/json',
        'X-Test-Type': 'comprehensive',
        'X-Load-Test': 'true'
      }
    }
  );
  
  check(branchResponse, {
    'branch creation status is 201': (r) => r.status === 201,
    'branch creation response time < 500ms': (r) => r.timings.duration < 500,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 2 + 1);
  
  // Create session (Level 4-5 operations)
  let sessionResponse = http.post(
    \/api/v1/sessions,
    JSON.stringify(payloads.createSession),
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer loadtest-token'
      }
    }
  );
  
  check(sessionResponse, {
    'session creation status is 201': (r) => r.status === 201,
    'session response time < 300ms': (r) => r.timings.duration < 300,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 1 + 0.5);
  
  // AI optimization request (Level 6-8 operations)
  let aiResponse = http.get(\/api/v1/ai/predictions?branch_id=\);
  check(aiResponse, {
    'AI prediction status is 200': (r) => r.status === 200,
    'AI response time < 1000ms': (r) => r.timings.duration < 1000,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 3 + 1);
  
  // Event creation (Real-time processing)
  let eventResponse = http.post(
    \/api/v1/events,
    JSON.stringify(payloads.createEvent),
    {
      headers: {
        'Content-Type': 'application/json'
      }
    }
  );
  
  check(eventResponse, {
    'event creation status is 202': (r) => r.status === 202,
    'event response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);
  
  // Analytics query
  let analyticsResponse = http.get(\/api/v1/analytics?timeframe=1h);
  check(analyticsResponse, {
    'analytics status is 200': (r) => r.status === 200,
    'analytics response time < 800ms': (r) => r.timings.duration < 800,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 2 + 0.5);
}

// Setup function
export function setup() {
  console.log('🚀 Starting comprehensive load test');
  console.log('📊 Target users: 1000');
  console.log('⏱️  Duration: 2h');
  console.log('📈 Ramp up: 300s');
  return { timestamp: new Date().toISOString() };
}

// Teardown function
export function teardown(data) {
  console.log('✅ Load test completed');
  console.log('📊 Started at: ' + data.timestamp);
  console.log('🏁 Finished at: ' + new Date().toISOString());
}

// Custom summary report
export function handleSummary(data) {
  return {
    'loadtest-results.html': htmlReport(data),
    'loadtest-summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
