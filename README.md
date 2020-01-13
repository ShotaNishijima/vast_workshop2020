## 時空間CPUE標準化ソフトvastのワークショップ

- 日時：2/7 (金) 13:30 - 17:30
- 場所：中央水産研究所 第2会議室
- プログラム：
  - 13:30-13:40 趣旨説明
  - 13:40-14:15 cpue標準化～vastとは？
  - 14:15-15:30 [vastの基礎](https://github.com/Yuki-Kanamori/vast_workshop2020/blob/master/vastの基礎1_1.0.pdf)（ハンズオン形式；インストール，インプットの作り方，簡単な実行，アウトプットの見方，など）
  - 15:30-15:45 休憩
  - 15:45-16:15 細かい設定などの質疑応答
  - 16:15-17:30 vastの基礎続き（ハンズオン形式 ）；vastの応用（事例紹介，総合討論，など）

## 持ち物
* PC
* 解析したいデータ
  * tidy形式にしてください
* プログラム内容の参考にしたいので，PCとデータについて[こちら](https://chouseisan.com/s?h=19541a5a62ea4d04acee9f9be0358091)に記入をお願いします．匿名で構いません

## 事前準備
- vastパッケージのインストール
https://github.com/James-Thorson-NOAA/VAST
  - リンク先の『Installation Instructions』を参照してください．
  - インストールが出来ない場合は，『Known instllation/ usage issues』部分も参考にしてください．
  - インストールがうまくいかないことはよくありますので，うまくいかなくても大丈夫です．できるだけ最新バージョンのRなどにするとうまくいくようです．
  - 上手くいかなかった場合はこのgithub上のissueに上げていただけると助かります（情報共有のため）
  - エラーの解決策もissueに載っている可能性があるので参照してください（例えば[Windows](https://github.com/ShotaNishijima/vast_workshop2020/issues/1), [Mac](https://github.com/ShotaNishijima/vast_workshop2020/issues/2)）

- テストコード
https://gist.github.com/Yuki-Kanamori/42d04d6235170f27e6d7dfce589722a2

  - 上記のリンクにテストコードがありますので、走らせていただき、動くか確認お願いします  
    **2行目のディレクトリの設定以外は，何も変更をしないで大丈夫です**
  - 最新版のFishStatsUtils（2.3.4）の場合は，156-176行目でエラーが出ますので，[こちら](https://github.com/ShotaNishijima/vast_workshop2020/issues/4)をご覧ください
* プログラム内容の参考にしたいので，進捗状況について[こちら](https://chouseisan.com/s?h=a99aa7cba2ec4b6fba8e1a6765de3149)に記入をお願いします．匿名で構いません

## 参考資料    
### **論文**
* Thorson JT (2019) Guidance for decisions using the Vector Autoregressive Spatio-Temporal (VAST) package in stock, ecosystem, habitat and climate assessments. Fish Res 210:143–161
https://doi.org/10.1016/j.fishres.2018.10.013
* Kanamori Y, Takasuka A, Nishijima S, Okamura H (2019) Climate change shifts the spawning ground northward and extends the spawning period of chub mackerel in the western North Pacific. MEPS 624:155–166
https://doi.org/10.3354/meps13037    
### **描画**
`{ggvast}` https://github.com/Yuki-Kanamori/ggvast    
### **vastのコード**
* 複数のカテゴリーで解析した例（masaVAST）準備中
* catchability covariateに他種の密度，overdispersion configに年と月の交互作用を入れた例（[gomasaVAST](https://github.com/Yuki-Kanamori/gomasaVAST)）
* 共変量に水温を入れた例（masaVAST_NPFC2018）準備中
* catchability covariateに漁具を入れた例（chiVAST）準備中
