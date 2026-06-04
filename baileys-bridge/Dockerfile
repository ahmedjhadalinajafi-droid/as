FROM node:20-slim

WORKDIR /app

# تثبيت الاعتماديات أولًا للاستفادة من ذاكرة الطبقات، مع محاولات إعادة عند تعثّر الشبكة
COPY package.json ./
RUN npm config set fetch-retries 5 \
 && npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000 \
 && npm install --omit=dev --no-audit --no-fund

COPY index.js ./

# يحفظ جلسة واتساب هنا (يُربط بـ volume من docker-compose)
VOLUME ["/app/auth_info"]

EXPOSE 3100
CMD ["node", "index.js"]
