FROM python:3.10-slim

# 安装基础工具
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    gcc \
    musl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# ===========================
# 1. 部署 OpenAI Edge TTS (端口 5050)
# ===========================
WORKDIR /app/tts
RUN git clone https://github.com/travisvn/openai-edge-tts.git .
RUN pip install --no-cache-dir -r requirements.txt

# ===========================
# 2. 部署 Doubao Free API (原端口 8000 -> 改为 3000)
# ===========================
WORKDIR /app/doubao
RUN git clone https://github.com/1994qrq/2025doubao-free-api.git .
# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# --- 关键步骤：修改端口 ---
# 使用 sed 命令查找当前目录下所有 .py 文件，把 8000 替换为 3000
# 这样做是为了把 8000 端口让给 Nginx
RUN grep -rl "8000" . | xargs sed -i 's/8000/3000/g'

# ===========================
# 3. 配置 Nginx 和 Supervisor
# ===========================
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 环境变量
ENV PORT=8000

# 暴露端口给 Koyeb
EXPOSE 8000

# 启动
CMD ["/usr/bin/supervisord"]
