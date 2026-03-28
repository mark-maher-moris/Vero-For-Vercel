export default function handler(req, res) {
  const { code, state } = req.query;

  if (!code) {
    return res.status(400).send('Missing code');
  }

  // Redirect to the mobile app's custom scheme
  const mobileRedirect = `com.buildagon.vero://auth?code=${code}${state ? `&state=${state}` : ''}`;

  console.log('Redirecting to:', mobileRedirect);

  res.setHeader('Location', mobileRedirect);
  return res.status(302).send();
}
