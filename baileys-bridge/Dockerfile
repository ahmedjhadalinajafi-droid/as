FROM node:20-slim

WORKDIR /app

# git مطلوب: إحدى اعتماديات Baileys (libsignal) تُجلب من GitHub
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# تثبيت الاعتماديات أولًا للاستفادة من ذاكرة الطبقات
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund

COPY index.js ./

# يحفظ جلسة واتساب هنا (يُربط بـ volume من docker-compose)
VOLUME ["/app/auth_info"]

EXPOSE 3100
CMD ["node", "index.js"]
