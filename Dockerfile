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

# 2. 安装 Node.js 20 (为了运行豆包项目)
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
# 4. 部署 Doubao Free API (Node.js) - 已更换为 Bitsea1 版本
# ===========================
WORKDIR /app/doubao
# --- 这里修改了仓库地址 ---
RUN git clone https://github.com/Bitsea1/doubao-free-api.git .
# 安装 Node 依赖并构建
RUN yarn install
RUN yarn run build

# --- 端口处理 ---
# Bitsea1 默认端口可能是 3000 或 8000。
# 我们尝试把源码里所有的 8000 改为 3000，防止跟 Nginx (8000) 冲突
# 如果它本身就是 3000，这行命令也不会报错，只是不替换而已
RUN grep -rl "8000" . | xargs sed -i 's/8000/3000/g' || true

# ===========================
# 5. 配置 Nginx 和 Supervisor
# ===========================
WORKDIR /app
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 环境变量
ENV PORT=8000
EXPOSE 8000

# 启动
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
