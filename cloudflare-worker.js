# Cloudflare Worker for Global Edge Routing
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const country = request.cf.country;
    const region = getRegionFromCountry(country);
    
    // Route to nearest edge
    const edgeEndpoint = getEdgeEndpoint(region);
    const edgeUrl = new URL(url.pathname + url.search, edgeEndpoint);
    
    // Add edge headers
    const edgeRequest = new Request(edgeUrl, {
      method: request.method,
      headers: {
        ...request.headers,
        'X-Edge-Region': region,
        'X-Original-Country': country,
        'X-Framework-Version': 'v2.1.0-edge'
      },
      body: request.body
    });
    
    const response = await fetch(edgeRequest);
    
    // Add caching headers
    const cacheHeaders = {
      'Cache-Control': 'public, max-age=300',
      'CDN-Cache-Control': 'public, max-age=86400',
      'X-Edge-Hit': response.headers.get('X-Edge-Hit') || 'MISS',
      'X-Response-Time': Date.now() - startTime
    };
    
    return new Response(response.body, {
      status: response.status,
      headers: {
        ...response.headers,
        ...cacheHeaders
      }
    });
  }
};

function getRegionFromCountry(country) {
  const regionMap = {
    'US': 'us-east',
    'CA': 'us-east',
    'MX': 'us-west',
    'BR': 'latam-south',
    'AR': 'latam-south',
    'GB': 'eu-central',
    'DE': 'eu-central',
    'FR': 'eu-central',
    'JP': 'asia-pacific',
    'KR': 'asia-pacific',
    'SG': 'asia-pacific',
    'AU': 'au-east',
    'NZ': 'au-east'
  };
  return regionMap[country] || 'us-east';
}

function getEdgeEndpoint(region) {
  const endpoints = {
    'us-east': 'https://edge-us-east.branching-framework.com',
    'us-west': 'https://edge-us-west.branching-framework.com',
    'eu-central': 'https://edge-eu.branching-framework.com',
    'asia-pacific': 'https://edge-apac.branching-framework.com',
    'au-east': 'https://edge-au.branching-framework.com',
    'latam-south': 'https://edge-latam.branching-framework.com'
  };
  return endpoints[region];
}
