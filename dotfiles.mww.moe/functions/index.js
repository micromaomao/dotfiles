export async function onRequestGet({ request, env }) {
  let original_request_url = new URL(request.url);
  return await env.ASSETS.fetch(new Request(original_request_url.origin + "/debian.sh"));
}
