FROM node:20-slim

WORKDIR /app

# تثبيت الاعتماديات أولًا للاستفادة من ذاكرة الطبقات
COPY package.json ./
RUN npm install --omit=dev

COPY index.js ./

# يحفظ جلسة واتساب هنا (يُربط بـ volume من docker-compose)
VOLUME ["/app/auth_info"]

EXPOSE 3000
CMD ["node", "index.js"]
