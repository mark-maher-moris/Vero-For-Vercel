export default function handler(req, res) {
  const { code, state, error, error_description } = req.query;

  console.log('Received callback query:', JSON.stringify(req.query, null, 2));

  if (error) {
    console.error('Vercel OAuth Error:', error, error_description);
    return res.status(400).send(`Vercel OAuth Error: ${error}\nDescription: ${error_description || 'No description provided'}`);
  }

  if (!code) {
    console.error('Missing code in query parameters:', req.query);
    return res.status(400).send(`Missing code. Received parameters: ${Object.keys(req.query).join(', ') || 'none'}`);
  }

  // Redirect to the mobile app's custom scheme
  const mobileRedirect = `com.buildagon.vero://auth?code=${code}${state ? `&state=${state}` : ''}`;
  console.log('Redirecting to mobile app:', mobileRedirect);

  res.setHeader('Location', mobileRedirect);
  return res.status(302).send();
}
