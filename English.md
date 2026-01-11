# JXWAF

## Introduction

JXWAF6 Standard Edition is a Web Application Firewall based on AI large models.

## Features

- Data Statistics
- Attack Events
- Attack Logs
- Website Protection
  - Website Integration
  - Certificate Management
- AI Protection Configuration
  - Web Security Protection
  - AI Analysis Records
- Protection Configuration
  - Web Protection Rules
  - Traffic Protection Rules
  - IP Region Blocking
  - Whitelist Rules
- Protection Components
- Node Status

## Deployment

### Environment Requirements

- Server System: Debian 12.x
- Minimum Server Configuration: 4 cores, 8GB RAM

### One-Click Deployment

Server IP Addresses:
- Public Address: 47.120.63.196
- Internal Address: 172.29.198.241

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 2. Clone Repository
git clone https://github.com/jx-sec/jxwaf.git

# 3. Start Container
cd jxwaf/standard
docker compose up -d
```

WAF Console Address: http://47.120.63.196:8000

## Configuration Instructions

### Docker Compose File Configuration

- **JXWAF_MODEL_QUERY**  
  Whether to enable JXWAF large model semantic caching service and join the group immunity network. Values: `true` or `false`.  
  - **Large Model Semantic Caching Service**: When encountering unknown requests, it first queries the cache. If a hit occurs, there's no need to query through the large model, which can significantly save large model usage costs.
  - **Group Immunity Network**: When other WAFs detect new attack POCs, they synchronize model parameters to the local WAF through the group immunity network, enabling real-time acquisition of the latest detection capabilities.

- **AI_BACKUP_WAF_URL**  
  When the large model service is unavailable for various reasons, this configuration can be used to obtain detection capabilities from other WAFs. Since requests need to be forwarded to the target WAF, there may be data leakage risks.

### Console AI Protection Configuration

#### Protection Mode Description

Unlike traditional WAFs' black-and-white detection mode, AI WAF adopts a **non-white-then-black** detection mode.

- **Online Learning**  
  Trains the local model based on online business traffic without taking any actions.
  
- **Online Protection - Business Priority**  
  Known attack traffic is intercepted. Unknown traffic is first allowed through, and after AI analysis produces results, the local model is synchronously updated for processing.

- **Online Protection - Security Priority**  
  Known attack traffic is intercepted. Unknown traffic is first intercepted, and after AI analysis produces results, the local model is synchronously updated for processing.

- **Offline Protection**  
  Both known attack traffic and unknown traffic are intercepted, and the local model is no longer updated.

## Protection Effectiveness Comparison

**Testing Method**:  
```bash
docker run --rm --net=host ccr.ccs.tencentyun.com/jxwaf/blazehttp:latest /app/blazehttp -t http://172.30.42.104/xxx
```
Using the sample set provided by the blazehttp project from Chaitin, results are as follows:

### JXWAF6 Standard Edition - DeepSeek
- Total Samples: 33877, Successful: 33877, Errors: 0
- Detection Rate: 41.03% (Malicious Samples: 658, Correctly Blocked: 270, Missed: 388)
- False Positive Rate: 0.14% (Normal Samples: 33219, Correctly Allowed: 33172, False Blocked: 47)
- Accuracy: 98.72% ((Correctly Blocked + Correctly Allowed) / Total Samples)
- Average Processing Time: 28.19 milliseconds

### JXWAF5 - Semantic Analysis Engine
- Total Samples: 33877, Successful: 33877, Errors: 0
- Detection Rate: 26.90% (Malicious Samples: 658, Correctly Blocked: 177, Missed: 481)
- False Positive Rate: 0.20% (Normal Samples: 33219, Correctly Allowed: 33153, False Blocked: 66)
- Accuracy: 98.39%
- Average Processing Time: 43.68 milliseconds

### Cloud WAF A - Default Configuration
- Total Samples: 33877, Successful: 33877, Errors: 0
- Detection Rate: 40.12% (Malicious Samples: 658, Correctly Blocked: 264, Missed: 394)
- False Positive Rate: 0.23% (Normal Samples: 33219, Correctly Allowed: 33143, False Blocked: 76)
- Accuracy: 98.61%
- Average Processing Time: 43.36 milliseconds

### WAF B - Official Demo Configuration
- Total Samples: 33877, Successful: 33877, Errors: 0
- Detection Rate: 44.38% (Malicious Samples: 658, Correctly Blocked: 292, Missed: 366)
- False Positive Rate: 0.19% (Normal Samples: 33219, Correctly Allowed: 33155, False Blocked: 64)
- Accuracy: 98.73%
- Average Processing Time: 33.02 milliseconds

**Conclusion**: JXWAF6 Standard Edition shows significant improvement in detection effectiveness compared to JXWAF5, reaching commercial WAF detection standards.

## WeChat Official Account

Welcome to follow our WeChat Official Account for future updates and technical sharing.

<kbd><img src="img/wx_code.jpeg" width="500"></kbd>

## Contributors

- [chenjc](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)
- [thankfly](https://github.com/thankfly)

## BUG & Requirements

- WeChat: 574604532 (Please add note "jxwaf" when connecting)
