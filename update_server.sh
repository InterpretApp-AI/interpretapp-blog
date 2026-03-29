#!/bin/bash
set -e

SERVER_IP="149.248.18.118"
SSH_KEY="$HOME/.ssh/id_rsa"
BLOG_DIR="$HOME/workplace/interpretapp-blog"
PORT=4000

echo "Building blog locally..."
cd "$BLOG_DIR"
npm install
npm run build

echo "Syncing build to server..."
rsync -az --delete -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
  dist/ root@$SERVER_IP:~/interpretapp-blog/dist/

echo "Restarting serve on port $PORT..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@$SERVER_IP "
  pkill -f 'serve.*$PORT\|serve.*interpretapp-blog' 2>/dev/null || true
  sleep 1
  nohup serve -l $PORT ~/interpretapp-blog/dist > /tmp/blog.log 2>&1 &
  sleep 2
  if ss -tlnp | grep -q ':$PORT'; then
    echo 'Blog deployed successfully on port $PORT'
  else
    echo 'ERROR: serve failed to start'
    cat /tmp/blog.log
    exit 1
  fi
"

echo "Blog deployment complete."
echo ""
echo "Next: ensure nginx proxies interpretapp.ai/blog to localhost:$PORT"
echo "  location /blog {"
echo "    proxy_pass http://localhost:$PORT;"
echo "    proxy_set_header Host \$host;"
echo "  }"
