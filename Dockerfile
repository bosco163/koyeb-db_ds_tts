
FROM python:3.10-slim

# 1. 安装基础工具
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    curl \
    gnupg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Node.js 20
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs && npm install -g yarn

# ===========================
# 3. 部署 OpenAI Edge TTS (Python)
# ===========================
WORKDIR /app/tts
RUN git clone https://github.com/travisvn/openai-edge-tts.git .
RUN pip install --no-cache-dir -r requirements.txt

# ===========================
# 4. 部署 Doubao Free API (Node.js)
# ===========================
WORKDIR /app/doubao
RUN git clone https://github.com/Bitsea1/doubao-free-api.git .
RUN yarn install
RUN yarn run build
# 防止端口冲突，尝试替换源码默认端口
RUN grep -rl "8000" . | xargs sed -i 's/8000/3000/g' || true

# ===========================
# 5. 部署 DeepSeek2API (Python)
# ===========================
WORKDIR /app/deepseek
RUN git clone https://github.com/iidamie/deepseek2api.git .
RUN pip install --no-cache-dir -r requirements.txt
# 不再强制修改端口，直接使用其默认的 5001

# ===========================
# 6. 配置 Nginx 和 Supervisor
# ===========================
WORKDIR /app
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 环境变量
ENV PORT=8000
EXPOSE 8000

# 启动
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
