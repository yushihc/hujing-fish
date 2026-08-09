#!/usr/bin/env bash
# 虎井嶼手釣魚 － 後端部署（唯一入口，不要手動跑 clasp）
#
# 用法：./deploy-backend.sh "23 - 這次改了什麼"
#
# 為什麼要有這個腳本：
#   Code.js 裡有家人的真實姓名與電話，所以不能進公開的 GitHub repo。
#   雲端硬碟那份備份是「除了 Google Apps Script 本身以外的唯一副本」。
#   以前備份要手動複製，結果程式改了六次、備份停在五天前。
#   現在把「備份」綁進部署流程裡，忘不掉。
set -e

DESC="${1:-}"
if [ -z "$DESC" ]; then
  echo "請給這次部署的說明，例如："
  echo "  ./deploy-backend.sh \"24 - 修正某某問題\""
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/gas-backend"
BACKUP="C:/Users/SHIHYU-RAZER/AI-Agent/Projects/生活/hujing-fish/📄 企劃書與報告/後端原始碼備份"
DEPLOY_ID="AKfycbzWsIIe9jZXdLXe2q2XqsB4S83FrDNAU9zDMu-Vqqam63vhNnqrIrEi8G4CavTVLvBxaw"

echo "① 語法檢查"
node --check "$SRC/Code.js"

echo "② 推上 Google Apps Script"
(cd "$SRC" && npx --yes @google/clasp push -f) > /dev/null

echo "③ 部署到固定網址（網址不會變）"
(cd "$SRC" && npx --yes @google/clasp deploy -i "$DEPLOY_ID" -d "$DESC") | tail -1

echo "④ 備份到雲端硬碟"
mkdir -p "$BACKUP"
cp "$SRC/Code.js" "$BACKUP/Code.js"
cp "$SRC/appsscript.json" "$BACKUP/appsscript.json"
echo "   已更新 $BACKUP/Code.js（$(wc -c < "$SRC/Code.js") bytes）"

echo "⑤ 讀取測試（確認線上真的活著）"
# ⚠️ 這段要寫成檔案再執行。用 node - <<'JS' 從 stdin 餵進去的話，
#    那個執行環境裡的 URL 不是建構子，fetch 會直接爆掉。
TESTJS="$(mktemp -t hujing-test-XXXXXX.js)"
cat > "$TESTJS" <<'JS'
const URL = "https://script.google.com/macros/s/AKfycbzWsIIe9jZXdLXe2q2XqsB4S83FrDNAU9zDMu-Vqqam63vhNnqrIrEi8G4CavTVLvBxaw/exec";
(async () => {
  const r = await fetch(URL, {
    method: "POST", headers: { "Content-Type": "text/plain;charset=utf-8" },
    body: JSON.stringify({ action: "總覽" }),
  });
  const t = await r.text();
  // 沒帶帳密，預期會回「帳號或密碼不對」－ 能回這句就代表後端活著且回的是 JSON
  if (t.indexOf("帳號或密碼不對") >= 0) console.log("   ✅ 後端正常回應");
  else { console.log("   ⚠️ 回應怪怪的：" + t.slice(0, 120)); process.exit(1); }
})();
JS
node "$TESTJS"
rm -f "$TESTJS"

echo
echo "完成。備份、部署、測試都做了。"
