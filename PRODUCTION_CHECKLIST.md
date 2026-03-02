# imprompt generator - Production Deployment Checklist

Complete this checklist before deploying to production.

## Security Checklist

- [ ] **Secrets Management**
  - [ ] JWT_SECRET changed to strong random value: `openssl rand -hex 32`
  - [ ] DB_PASSWORD changed to strong random value: `openssl rand -base64 32`
  - [ ] REDIS_PASSWORD set to strong value
  - [ ] All default credentials changed
  - [ ] Secrets stored in secure vault (not in git)

- [ ] **Network Security**
  - [ ] HTTPS/TLS enabled on API endpoint
  - [ ] Firewall rules configured
  - [ ] Database port (5432) not exposed to public internet
  - [ ] Redis port (6379) not exposed to public internet
  - [ ] WAF (Web Application Firewall) configured
  - [ ] DDoS protection enabled

- [ ] **SSL/TLS Configuration**
  - [ ] Valid SSL certificate obtained
  - [ ] Certificate installed on API endpoint
  - [ ] CORS_ORIGIN updated with HTTPS domain
  - [ ] HSTS headers configured
  - [ ] Certificate auto-renewal configured

- [ ] **Application Security**
  - [ ] CORS properly configured for your domain only
  - [ ] Rate limiting enabled and tested
  - [ ] Input validation on all endpoints verified
  - [ ] File upload restrictions configured
  - [ ] Error messages don't expose sensitive info
  - [ ] Logging doesn't capture passwords/tokens

- [ ] **Database Security**
  - [ ] Database backups automated (daily minimum)
  - [ ] Backup retention policy set (30+ days recommended)
  - [ ] Backup encryption enabled
  - [ ] Database encryption at rest enabled
  - [ ] SQL injection protection verified
  - [ ] Row-level security implemented if needed

- [ ] **Data Protection**
  - [ ] Encryption in transit (HTTPS) enabled
  - [ ] Encryption at rest enabled for databases
  - [ ] Sensitive data encryption implemented
  - [ ] PII (Personally Identifiable Information) handling policy in place
  - [ ] GDPR compliance verified if applicable

## Infrastructure Checklist

- [ ] **Deployment**
  - [ ] Server provisioned with recommended specs
  - [ ] OS security updates applied
  - [ ] Docker and Docker Compose installed
  - [ ] File system mounted with noexec on /uploads
  - [ ] SELinux/AppArmor configured

- [ ] **Monitoring & Logging**
  - [ ] Application health checks configured
  - [ ] Monitoring system set up (Prometheus, Datadog, etc.)
  - [ ] Alerting rules configured
  - [ ] Log aggregation configured (ELK, Splunk, etc.)
  - [ ] Centralized logging configured
  - [ ] Log retention policy set

- [ ] **Backups & Disaster Recovery**
  - [ ] Automated backup jobs scheduled
  - [ ] Backup storage secured
  - [ ] Restore procedure tested
  - [ ] Disaster recovery plan documented
  - [ ] RTO (Recovery Time Objective) defined
  - [ ] RPO (Recovery Point Objective) defined

- [ ] **Performance**
  - [ ] Load testing completed
  - [ ] Cache strategy configured
  - [ ] CDN configured for static assets
  - [ ] Database indexes optimized
  - [ ] Connection pooling configured

## Operational Checklist

- [ ] **Documentation**
  - [ ] Deployment runbook created
  - [ ] Operations manual documented
  - [ ] Incident response plan created
  - [ ] Escalation procedures documented
  - [ ] Team access procedures documented

- [ ] **Team Preparation**
  - [ ] Team trained on deployment process
  - [ ] Team trained on incident response
  - [ ] On-call rotation established
  - [ ] Admin access provisioned
  - [ ] SSH key management configured

- [ ] **Testing**
  - [ ] Smoke tests passed
  - [ ] Health checks passing
  - [ ] Integration tests passed
  - [ ] Performance tests passed
  - [ ] Failover testing completed

- [ ] **Compliance & Legal**
  - [ ] Security audit completed
  - [ ] Penetration testing completed
  - [ ] Compliance requirements verified
  - [ ] Terms of Service reviewed
  - [ ] Privacy policy updated
  - [ ] Cookie consent configured

## Configuration Checklist

Review your `docker-compose.prod.yml` and `.env`:

```bash
# Critical environment variables
✓ NODE_ENV=production
✓ JWT_SECRET=<strong-random-value>
✓ DB_PASSWORD=<strong-password>
✓ CORS_ORIGIN=https://yourdomain.com
✓ REDIS_PASSWORD=<strong-password>
✓ RATE_LIMIT_MAX_REQUESTS=100
✓ LOG_LEVEL=info (not debug)
✓ UPLOAD_MAX_FILE_SIZE=52428800 (50MB)
```

Verify ports and services:
```bash
✓ API Gateway: 3000
✓ PostgreSQL: 5432 (internal, not exposed)
✓ Redis: 6379 (internal, not exposed)
✓ Ollama: 11434 (internal, not exposed)
```

## Pre-Deployment Testing

1. **Run locally with production docker-compose**
   ```bash
   ./setup-prod.sh
   ```

2. **Test all API endpoints**
   ```bash
   curl https://yourdomain.com/health
   curl -X POST https://yourdomain.com/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

3. **Test database operations**
   ```bash
   docker-compose -f docker-compose.prod.yml exec postgres \
     psql -U ai -d aisaas -c "SELECT COUNT(*) FROM users;"
   ```

4. **Test file uploads**
   ```bash
   # Upload a test PDF
   curl -X POST https://yourdomain.com/upload \
     -H "Authorization: Bearer <token>" \
     -F "file=@test.pdf"
   ```

## Post-Deployment

- [ ] Monitor API logs for errors: `docker-compose -f docker-compose.prod.yml logs -f api`
- [ ] Verify all services are healthy: `docker-compose -f docker-compose.prod.yml ps`
- [ ] Check CPU and memory usage
- [ ] Verify database backups are running
- [ ] Set up uptime monitoring
- [ ] Configure alerting for critical errors
- [ ] Test incident response plan
- [ ] Review security logs

## Performance Targets

- [ ] API response time < 200ms (p99)
- [ ] Database query time < 100ms
- [ ] Uptime: 99.9% (43 minutes downtime/month maximum)
- [ ] Error rate: < 0.1%

## Rollback Plan

Document your rollback procedure:

```bash
# If immediate rollback needed:
docker-compose -f docker-compose.prod.yml down
git checkout <previous-version-tag>
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

Ensure you can rollback within 5-10 minutes if critical issues occur.

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Approved By:** _______________

**Sign-off only after all checkboxes are completed.**
