# --- 1. ビルド用ステージ ---
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- 2. 実行用（本番）ステージ ---
FROM node:22-alpine AS runner
WORKDIR /app

# 本番環境のセキュリティを高めるため、root権限を排除して一般ユーザー(nextjs)を作成
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# standalone出力モードに必要な最小限のファイル群だけを builder からコピー
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT 3000

# output: "standalone" の場合、起動は node server.js を直接叩くのが正解です
CMD ["node", "server.js"]

