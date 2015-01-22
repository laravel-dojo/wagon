# wagon：免安裝可攜的 Laravel 開發環境

### TL;DR：這是一個整合 cmder、git、uwamp、composer 的懶人包，只要下載後就可以直接擁有一個免安裝可攜的 Laravel 開發環境 :)


## 這是什麼？

為了安裝 Laravel 的開發環境而傷腦筋嗎？wagon 整合了 cmder、git、UwAmp、composer 成一個免安裝且可攜的 Laravel 開發環境，您可以把它想像成 Winodws 版的小型 Homestead！降低您學習 Laravel 的入門門檻，若測試完不滿意，您還可以隨時刪除(不用解除安裝)，完全沒付擔，現在就來體驗！

![Screenshot1](http://www.laravel-dojo.com/assets/img/opensource/wagon-screenshot.png)

更多詳細介紹可參考：<http://www.laravel-dojo.com/opensource/wagon>

## 有哪些好料？

在 wagon 裡已經幫您整合好以下軟體，皆為免安裝版本：

* [cmder](http://bliker.github.io/cmder/) 1.1.4.1
* [UwAmp](http://www.uwamp.com/en/) 3.0.2 (Apache, MySQL, [php 5.6.4-Win32-VC11-x86](http://windows.php.net/download/))
* [msysgit](https://msysgit.github.io/) 1.9.5
* [7-zip](http://www.7-zip.org/download.html) 9.20
* [composer](https://getcomposer.org/doc/00-intro.md#manual-installation) 1.0-dev
* [laravel-installer](http://laravel.com/docs/4.2/installation#install-laravel) 1.1
* [laravel envoy](http://laravel.com/docs/4.2/ssh#envoy-task-runner) 1.0.17
* [laravel](http://laravel.com/docs/4.2/installation#install-composer) 4.2.11

## 使用方式

* 請先下載/安裝 [Visual C++ 可轉散發套件 2012](http://www.microsoft.com/zh-tw/download/details.aspx?id=30679)
* 下載 wagon
* 解壓縮至您想要的位置，如 `c:\wagon`
* 依以下預設設定啟動對應的軟體即可開始使用

## 環境預設設定

* cmder 放置於，`wagon\cmder\Cmder.exe`，點擊兩次即可啟動，啟動時會自動載入獨立環境變數，並把當前位置設定在 `wagon\uwamp\www`，包括：
	* PHP 5.6.4：`wagon\uwamp\bin\php\php-5.6.4-Win32-VC11-x86\php.exe`
	* Composer：`wagon\composer\composer.bat`
	* Composer Packages：`wagon\composer\verdor\bin`
	* Git：`wagon\git\bin`
* UwAmp 放置於 `wagon\uwamp\UwAmp.exe`，點擊兩次即可啟動，預設設定如下：
	* Apache 已啟用 rewrite module、Document Root 設定在 `wagon\uwamp\www\laravel\public`、port 改設定為 `8000`
	* MySQL port 改設定為 `33060`，可用 `root`/`root` 登入
	* phpmyadmin 位置為 `http://localhost:8000/phpmyadmin`
* laravel 放置於 `wagon\uwamp\www\laravel`，要使用這個 app 的話，請先在 `bootstrap/start.php` 裡設定 `hostname`，讓 laravel 的系統變數會對應至 `local`，資料庫預設使用 `laravel_local`