export async function routeRequest({ method, path, body }, service) {
  if (method === 'GET' && path === '/healthz') {
    return { status: 200, body: { ok: true } };
  }
  if (method === 'GET' && path === '/readiness') {
    const result = await service.readiness();
    return { status: result.ok ? 200 : 503, body: result };
  }
  if (method === 'POST' && path === '/verify') {
    const result = await service.verify(body);
    return { status: 200, body: result };
  }
  if (method === 'POST' && path === '/commit') {
    const result = await service.commit(body);
    return { status: result.committed ? 200 : 409, body: result };
  }
  return { status: 404, body: { error: 'not found' } };
}
