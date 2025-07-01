<template>
  <div class="legal-page">
    <div class="container">
      <div class="legal-content">
        <h1>特定商取引法に基づく表記</h1>
        
        <div class="legal-section">
          <h2>販売事業者名</h2>
          <p>CastChat運営者</p>
        </div>

        <div class="legal-section">
          <h2>運営責任者</h2>
          <p>CastChat運営者</p>
        </div>

        <div class="legal-section">
          <h2>連絡先</h2>
          <p>お問い合わせは以下のTwitterアカウントまでお願いいたします。</p>
          <p>Twitter：<a href="https://twitter.com/yokena45330" target="_blank" rel="noopener">@yokena45330</a></p>
          <p class="note">※電話番号でのお問い合わせは受け付けておりません。Twitterでのお問い合わせをお願いいたします。</p>
        </div>

        <div class="legal-section">
          <h2>販売価格</h2>
          <p>投げ銭は任意の金額でお受けいたします。</p>
        </div>

        <div class="legal-section">
          <h2>支払い方法</h2>
          <p>クレジットカード決済（Stripe）</p>
        </div>

        <div class="legal-section">
          <h2>返金・キャンセルについて</h2>
          <p>投げ銭は任意の寄付・支援の性質上、原則として返金には応じられません。</p>
          <p>ただし、システムエラーや不正な決済が発生した場合は、個別に対応いたします。</p>
        </div>

        <div class="legal-section">
          <h2>サイトURL</h2>
          <p><a href="https://www.castchat.jp" target="_blank" rel="noopener">https://www.castchat.jp</a></p>
        </div>

        <div class="legal-section">
          <h2>サービス内容</h2>
          <p>VRChatイベントキャスト募集掲示板の運営</p>
          <p>イベント投稿・応募・メッセージ機能の提供</p>
        </div>

        <div class="legal-section">
          <h2>投げ銭の用途</h2>
          <p>サイト運営費、サーバー費用、開発費等の支援として活用いたします。</p>
        </div>

        <div class="legal-section">
          <h2>更新日</h2>
          <p>2025年7月</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// 特定商取引法に基づく表記ページ
</script>

<style scoped>
.legal-page {
  padding: 2rem 0;
  background-color: #f8f9fa;
  min-height: 100vh;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 2rem;
}

.legal-content h1 {
  text-align: center;
  margin-bottom: 2rem;
  color: #333;
  font-size: 1.8rem;
  border-bottom: 2px solid #667eea;
  padding-bottom: 1rem;
}

.legal-section {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e1e5e9;
}

.legal-section:last-child {
  border-bottom: none;
}

.legal-section h2 {
  color: #667eea;
  font-size: 1.2rem;
  margin-bottom: 0.5rem;
  font-weight: 600;
}

.legal-section p {
  color: #555;
  line-height: 1.6;
  margin-bottom: 0.5rem;
}

.legal-section a {
  color: #667eea;
  text-decoration: none;
}

.legal-section a:hover {
  text-decoration: underline;
}

.note {
  background-color: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 4px;
  padding: 0.75rem;
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #856404;
}

@media (max-width: 768px) {
  .container {
    margin: 1rem;
    padding: 1.5rem;
  }
  
  .legal-content h1 {
    font-size: 1.5rem;
  }
}
</style> 