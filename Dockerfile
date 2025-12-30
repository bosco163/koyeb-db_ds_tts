FROM python:3.10-slim

# 1. 安装系统基础工具 (Nginx, Supervisor, Git, 编译工具)
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    gcc \
    musl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# ===========================
# 2. 部署 OpenAI Edge TTS (端口 5050)
# ===========================
WORKDIR /app/tts
RUN git clone https://github.com/travisvn/openai-edge-tts.git .
RUN pip install --no-cache-dir -r requirements.txt

# ===========================
# 3. 部署 Doubao Free API (原端口 8000 -> 改为 3000)
# ===========================
WORKDIR /app/doubao
RUN git clone https://github.com/1994qrq/2025doubao-free-api.git .

# --- 修正点开始 ---
# 原来的仓库没有 requirements.txt，所以我们手动安装这类项目常用的依赖
# 即使它以后加了文件，这行命令如果文件不存在也不会报错
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
# 手动补充安装该项目可能需要的核心库 (Bottle, Requests, Flask等)
RUN pip install --no-cache-dir bottle requests flask loguru
# --- 修正点结束 ---

# --- 关键步骤：修改端口 ---
# 强制把代码里所有的 8000 替换为 3000，防止和 Nginx 冲突
RUN grep -rl "8000" . | xargs sed -i 's/8000/3000/g'

# ===========================
# 4. 配置 Nginx 和 Supervisor
# ===========================
# 复制配置文件 (确保这俩文件在你的 GitHub 仓库根目录)
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 环境变量
ENV PORT=8000

# 暴露端口给 Koyeb
EXPOSE 8000

# 启动 Supervisor
CMD ["/usr/bin/supervisord"]
