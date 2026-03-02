const jwt = require('jsonwebtoken');

/**
 * JWT Authentication Middleware
 * Validates bearer token in Authorization header
 */
module.exports = (req, res, next) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({ 
        error: 'Missing authorization header',
        code: 'NO_TOKEN'
      });
    }
    
    const parts = authHeader.split(' ');
    
    if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
      return res.status(401).json({ 
        error: 'Invalid authorization header format. Use: Bearer <token>',
        code: 'INVALID_FORMAT'
      });
    }
    
    const token = parts[1];
    const secret = process.env.JWT_SECRET || 'change-me-in-production';
    
    // Verify and decode token
    try {
      const decoded = jwt.verify(token, secret);
      
      // Attach decoded token to request
      req.user = decoded;
      req.token = token;
      
      next();
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ 
          error: 'Token has expired',
          code: 'TOKEN_EXPIRED',
          expiresAt: err.expiredAt
        });
      }
      
      if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ 
          error: 'Invalid token',
          code: 'INVALID_TOKEN'
        });
      }
      
      throw err;
    }
  } catch (error) {
    console.error('[JWT MIDDLEWARE ERROR]', error);
    res.status(500).json({ 
      error: 'Authentication error',
      code: 'AUTH_ERROR'
    });
  }
};
