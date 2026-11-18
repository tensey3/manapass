import json
import firebase_admin
from firebase_admin import credentials, firestore

# Firebaseの初期化（秘密鍵を使用）
if not firebase_admin._apps:
  cred = credentials.Certificate('serviceAccountKey.json')
  firebase_admin.initialize_app(cred)

db = firestore.client()

# 登録したいJSONファイルのリスト（ここにファイルを追加していけばOK！）
target_files = [
    'assets/questions/2026_kamoku_a.json',
    'assets/questions/2025_kamoku_a.json',
    'assets/questions/2024_kamoku_a.json',  # ← カンマを追加しました！
    'assets/questions/2023_kamoku_a.json',
]

# 各ファイルを順番に読み込んで登録
for file_path in target_files:
  print(f'\n--- {file_path} の処理を開始します ---')
  try:
    with open(file_path, 'r', encoding='utf-8') as f:
      questions = json.load(f)

    for q in questions:
      doc_id = q['id']
      db.collection('questions').document(doc_id).set(q, merge=True)
      print(f'登録・更新完了: {doc_id} (年度: {q.get("year")})')

  except FileNotFoundError:
    print(f'⚠️ ファイルが見つかりませんでした: {file_path}')

print('\nすべてのファイルの同期・一括登録が完了しました！')