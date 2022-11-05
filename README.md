# wagon：免安裝可攜的 Laravel 開發環境

### TL;DR：這是一個整合 cmder、git、uwamp、composer 的懶人包，只要下載後就可以直接擁有一個免安裝可攜的 Laravel 開發環境 :)

### 警告：wagon 原始的設計用意，僅在於「免安裝」與「快速取得 Laravel 開發環境」，方便如工作坊等教學用途使用，並不具備所有的開發功能，請絕對不要使用於上線環境。若想取得標準的 Laravel 開發環境，建議使用 [Homestead](https://laravel.com/docs/homestead)。

## 這是什麼？

為了安裝 Laravel 的開發環境而傷腦筋嗎？wagon 整合了 cmder、git、UwAmp、composer 成一個免安裝且可攜的 Laravel 開發環境，您可以把它想像成 Winodws 版的精簡 Homestead！降低您學習 Laravel 的入門門檻，若測試完不滿意，您還可以隨時刪除(不用解除安裝)，完全沒付擔，現在就來體驗！

![Screenshot1](http://www.laravel-dojo.com/assets/img/opensource/wagon-screenshot.png)

更多詳細介紹可參考：<http://www.laravel-dojo.com/opensource/wagon>

## 有哪些好料？

在 wagon 裡已經幫您整合好以下軟體，皆為免安裝版本：

* [cmder](http://cmder.net/) 1.3.20
* [UwAmp](http://www.uwamp.com/en/) 3.1.0 (Apache, MySQL, PHP)
* [git for windows](https://github.com/git-for-windows/git) 2.38.1
* [adminer](https://www.adminer.org/) 4.8.1 
* [SQLite](https://www.sqlite.org/) 3.39.4
* [composer](https://getcomposer.org/) 2.4.4
* [laravel/installer](https://packagist.org/packages/laravel/installer) 4.2.17
* [laravel/envoy](https://packagist.org/packages/laravel/envoy) 2.8.4
* [psy/psysh](https://packagist.org/packages/psy/psysh) 0.11.8

## 使用方式

* 下載 wagon
* 自動解壓縮至指定位置，如 `c:\wagon`
* 依以下預設設定啟動對應的軟體即可開始使用

## 環境預設設定

* cmder 放置於，`wagon\cmder\Cmder.exe`，點擊兩次即可啟動，啟動時會自動載入獨立環境變數，並把當前位置設定在 `wagon\uwamp\www`，包括：
	* PHP：`wagon\uwamp\bin\php\php-*.*.*\php.exe`
	* Composer：`wagon\composer\composer.bat`
	* Composer Global Packages：`wagon\composer\verdor\bin`
	* Git：`wagon\git\bin`
* UwAmp 放置於 `wagon\uwamp\UwAmp.exe`，點擊兩次即可啟動，預設設定如下：
	* Apache 已啟用 rewrite module、Document Root 設定在 `wagon\uwamp\www\default`、port 改設定為 `8000`
	* MySQL port 改設定為 `33060`，可用 `root`/`root` 登入
	* adminer 位置為 `http://localhost:8000/adminer`
* laravel 放置於 `wagon\laravel`

## 建立 wagon 自動解壓檔

點擊執行 `build\build.cmd`，完成後 wagon 自動解壓檔將自動產生在 `build\wagon.exe`

## 注意事項

* 請安裝 Visual C++ 可轉散發套件 2012 及 2015-2022 的 x86 及 x64 共計 4 種版本，解決 Apache 無法啟動的問題
* wagon 可放置在系統任何位置，但請確認其路徑裡不可以有非英文字元。 (如：若要將 wagon 放置在桌面上，請確定您的使用者名稱不是中文)
