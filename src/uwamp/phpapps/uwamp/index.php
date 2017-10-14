<?php
$UWAMPFOLDER="../../";


//CODE TO ENCODE IMAGE IN PHP FILE
/*
$fp = fopen("favicon.ico",'r');
$data = fread ($fp, filesize ("favicon.ico"));
fclose ($fp);
echo base64_encode($data);
exit;
*/



if (isset($_REQUEST['getimg']))
{
	$IMAGE_FAVICON="AAABAAIAEBAAAAAAIABoBAAAJgAAACAgAAAAACAAqBAAAI4EAAAoAAAAEAAAACAAAAABACAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAdSspP75FQr+/REHFu0NAxbhBPsW0PjzFsTw6xa06OMWqODbFpjY0xaM0MsWfMjDFnDAuxZguLMWPKyi7ShYUL71EQcfxVlL/7VxZ/+pgXf/mXlv/4ltX/9tKRv/WR0T/0kVB/85DP//NTkv/yk5L/8JBPv+8ODX/tzUy/4YmJK29Q0DP61NP/+txbv/ysrD/8LGv/++wrv/nlZP/3Xd1/96CgP/koJ//5aqp/92WlP+7Ozf/tjUx/7IyL/+FJSK3uEE+z+VQTP/hT0z/88TD//zz8//88/P//PPz//vz8v/78vL/+/Ly//LY2P/CUlD/tDQx/7AxLv+sLyz/gSIgt7Q+O8/fTEn/20pG/9dKRv/ggoD/6q+u//HPzv/wzs3/5Kyq/9N+fP+6PDn/szMw/68wLf+qLiv/piso/3wgHbevOzjP2UlF/9VGQ//XXlv/78TD//35+f////////////35+f/qxcT/w19d/60wLf+pLSr/pCso/6AoJf94HRu3qjk2z9NFQv/TU1D/+u3s//////////////////////////////////37+//HeXf/oyon/58nJP+aJSL/cxoYt6Y2M8/OQj//45qY/////////////v39/9B9e/+3Pjv/vFJQ/9ifnv/+/Pz//Pj4/6xHRf+ZJCH/lCEf/28YFrehMzHPyD87/+q6uf///////////+3Ozf+yMi//rTAt/6ktKv+lKyj/yoeG///////YrKv/kyAe/48eG/9qFRO3nDEuz8I7OP/mtLP////////////itLP/rC8s/6csKf+jKif/nyck/5woJv/06en/+fPz/5AiH/+JGxj/ZhMRt5guK8+8ODX/2pWU////////////5cHA/6YrKf+iKSb/nSYk/5kkIf+UIR//2LCv//////+fSEb/gxcV/2EQDreTKynPtjUy/8dpZ/////////////Tm5v+gKCX/nCYj/5cjIP+TIR7/jx4b/8aQjv//////rmlo/30UEf9dDgy3jykmz7AxLv+wODX//Pn5///////+/v7/qkdE/5YiH/+SIB3/jR0b/4kbGP+9gYD//////7Z9fP93EQ7/WQsJt4omJM+rLiv/pisp/+TBwP///////////8mQj/+QHxz/jBwa/4caF/+DFxX/vIWD//////+5hoX/cQ0L/1QIB7eEIyHJpSso/6AoJf+6Z2X////////////06un/jyUi/4YZFv+CFhT/fRQS/8uiof//////s4B+/2wKCP9OBgSxVBUUS38gHdF+HhzXehwa15BPTteSVlTXj1RT13MhH9doEhDXZRAO12EODNdxLCvXgEpJ12UgHtdRBgTNLQIBOQAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8oAAAAIAAAAEAAAAABACAAAAAAAIAQAAAAAAAAAAAAAAAAAAAAAAAA////AQAAABE4FBNxZSQji2QkIotjIyKLYiMhi2EiIYtgIiCLXyEgi14hH4teIB+LXSAei1wfHotbHx2LWh4di1keHItYHRyLVx0bi1YcG4tVHBqLVRsai1QaGYtTGhmLUhkYi1EZGItQGBeLTxgXi0wXFokeCQhhAAAABf///wEAAAATiDEv2fJYVP/0WFT/8ldT/+9WUv/tVVH/61NQ/+lSTv/nUU3/5E9M/+JOSv/gTUn/3ktI/9xKR//ZSUX/10hE/9VGQ//TRUL/0URA/85DP//MQj7/ykA9/8g/PP/GPjv/wzw5/8E7OP+/Ojf/vTk1/7E0Mf9NFhW1AAAAA0caGX/zWFT/81hU//FWU//vV1P/7VlV/+tXVP/pVlP/51VR/+RUUP/iU0//4E9M/91LR//bSkb/2UlF/9ZHRP/URkP/0kVB/9BDQP/OQj//zEI+/8tFQv/JREH/x0M//8RBPv/BOzj/vjk2/7w4Nf+6NzT/uDYy/6YwLf8JAgJJcCgnn/JXU//wVlL/7lVR/+xXVP/tbGj/62pn/+lpZv/naGX/5Wdk/+NmY//hY2D/2ktH/9hIRf/WR0P/1EZC/9FEQf/PQ0D/zUI+/8xEQf/PV1T/z1pX/81ZVv/LWFX/xk5L/745Nv+7ODX/uTYz/7c1Mv+1NDH/szMw/yYKCm1vJyaf71ZS/+1UUf/rU0//6VJP/++Rjv/vl5X/7paU/+2Vk//rlZP/6pSS/+mTkf/jfXv/1kpH/9NFQv/RRED/zkM//85IRf/VZ2X/3YiG/92Miv/cjIr/2ouJ/9mJh//BRkP/uzc0/7g2M/+2NTL/tDQw/7IyL/+wMS7/JgoKb20nJZ/tVFD/6lNP/+hRTv/mUEz/7pGP//bNzP/2zcz/9c3M//XMy//0zMv/88zL//PLyv/ww8H/6qqo/+mqqP/rtrX/78jH/+/JyP/vycj/7sjH/+3Ix//tyMf/03x6/7o3NP+4NjL/tjQx/7MzMP+xMi//rzEu/60vLP8mCglvbCYkn+pST//nUU3/5VBM/+NOS//iV1P/+Nra//zw7//78O//+/Dv//vv7//77+//++/v//vv7//77+//+u/v//rv7//67+//+u/u//rv7v/57+7/+e7u/+Cmpf+6ODX/tzUy/7U0Mf+zMzD/sDEu/64wLf+sLyz/qi4r/yUKCW9rJSSf51FN/+RPTP/iTkr/4E1J/95MSP/hZWL/+OHg//339v/99/b//fb2//z29v/89vb//Pb2//z29v/89vb//Pb2//z29v/89vb//Pb2//ry8v/ZkpH/uTc0/7Y1Mv+0NDD/sjIv/7AxLv+uMC3/qy4r/6ktKv+nLCn/JAkJb2kkI5/kT0v/4k5K/99MSf/dS0j/20pG/9lJRf/ZUU7/6aCe//bb2v/34uL/9+Lh//fi4f/24uH/9uHh//bh4f/14eH/9eHg//Pb2//hp6X/w1NQ/7g2M/+2NDH/szMw/7EyL/+vMS7/rS8s/6suK/+oLSr/piwp/6QqJ/8kCQhvaCQin+FNSv/fTEj/3EtH/9pJRv/YSEX/1kdD/9RGQv/RREH/0UhF/9doZf/hkY//6rW0/+3Ew//tw8L/57Kx/9qMiv/LYV//vj88/7k2M/+3NTL/tTQx/7MzMP+xMS7/rjAt/6wvLP+qLiv/qCwp/6YrKP+jKif/oSkm/yMICG9nIyGf3kxI/9xKR//aSUX/10hE/9VGQ//TRUL/0URB/9djYP/rsrD/+erq//7+/v///////////////////////v7+//jq6v/ks7H/yGVj/7Q0Mf+yMi//sDEu/64wLf+rLiz/qS0q/6csKf+lKyj/oykn/6AoJf+eJyT/IggIb2UiIZ/bSkb/2UlF/9dHRP/URkP/0kVB/9FGQ//oqKb//vz8///////////////////////////////////////////////////////+/v7/6snI/7pOS/+tLyz/qy4r/6gtKv+mLCn/pCon/6IpJv+gKCX/nSck/5slIv8iCAdvZCEgn9hIRf/WR0P/1EZC/9FEQf/PQ0D/7Li2////////////////////////////////////////////////////////////////////////////+vLy/8BlY/+oLCn/piso/6MqJ/+hKSb/nycl/50mI/+bJSL/mCQh/yEHB29jIR+f1UdD/9NFQv/RREH/z0M//92Afv/+/v7/////////////////////////////////////////////////////////////////////////////////+/f3/7laV/+jKSf/oCgl/54nJP+cJiP/miQi/5gjIP+VIh//IAcGb2EgHp/SRUH/0ERA/85CP//MQT7/9NjX//////////////////////////////////jr6//RfXv/vUpI/7xKR//CX13/0ouK/+7W1f/+/v7/////////////////9Obm/6U0Mf+eJyT/myUj/5kkIf+XIyD/lSEf/5MgHv8gBwZvYB8dn89DQP/NQj//y0E9/85ST//+/v7////////////////////////////9+vr/xFpX/7U0Mf+zMzD/sTEu/64wLf+sLyz/qi4r/8h6eP/79vb/////////////////0p2c/5slIv+YJCH/liIg/5QhHv+SIB3/kB8c/x8GBm9fHh2fzEE+/8pAPf/IPzz/1XBt/////////////////////////////////+W4t/+0NDH/sjIv/7AxLv+uMC3/qy8s/6ktKv+nLCn/pSso/7thX//9+/v////////////79vb/oDUz/5YiH/+TIR7/kR8d/48eHP+NHRr/HwYFb10dHJ/KQDz/xz87/8U9Ov/We3n/////////////////////////////////0IKA/7EyL/+vMS7/rS8s/6suK/+pLSr/piwp/6QqJ/+iKSb/oCgl/9GZmP/////////////////FhoX/kyAe/5AfHP+OHhv/jBwa/4obGf8eBQVvXB0bn8c+O//EPTr/wjw4/9N0cv/////////////////////////////////Ga2j/rjAt/6wvLP+qLiv/qCwq/6YrKP+jKif/oSkm/58nJf+dJiP/oTMx//r19f///////////+jR0P+QHxz/jh0b/4scGf+JGxj/hxoX/x0FBW9aHBqfxDw5/8E7OP+/Ojf/yl9c/////////////////////////////////8RpZ/+sLyz/qS0q/6csKf+lKyj/oyon/6EoJf+eJyT/nCYj/5okIv+YIyD/2rKy/////////////v39/5YwLv+LHBn/iBoY/4YZF/+EGBX/HQUEb1kbGp/BOzj/vzo2/7w4Nf++QT7//v39////////////////////////////x3Z0/6ktKv+mLCn/pCoo/6IpJv+gKCX/nick/5slI/+ZJCH/lyMg/5UiH/+9d3X/////////////////rmJg/4gaF/+FGRb/gxcV/4EWFP8cBARvWBoZn745Nv+8ODX/uTcz/7c1Mv/04uL////////////////////////////RkI7/piso/6MqJ/+hKSb/nycl/50mI/+bJSL/mSQh/5YiIP+UIR7/kiAd/6ZLSf/////////////////DjIv/hRgW/4MXFf+AFhP/fhQS/xsEBG9XGhifuzc0/7k2M/+3NTL/tDQx/+S4t////////////////////////////+C2tf+jKif/oSgl/54nJP+cJiP/miQi/5gjIf+WIh//kyEe/5EfHf+PHhz/lCwp//7+/v///////////9Svrv+CFxT/gBUT/30UEv97ExD/GwQDb1UZF5+4NjP/tjQx/7QzMP+xMi//0YiG////////////////////////////9Obl/6AoJf+eJyT/myUj/5kkIf+XIyD/lSIf/5MgHv+QHxz/jh4b/4wcGv+LHRr/+/f3////////////48vK/38VE/99FBH/exIQ/3gRD/8aAwNvVBgXn7U0Mf+zMzD/sTIv/68wLf+7U1D//v7+///////////////////////+/v7/rElG/5slIv+ZJCH/liIg/5QhHv+SIB3/kB8c/44dG/+LHBr/iRsY/4caF//17ez////////////u4OD/fBMR/3oSEP94EQ7/dQ8N/xkDAm9SFxafsjIv/7AxLv+uMC3/rC8s/6ouK//16Oj////////////////////////////Iioj/mCMh/5YiH/+TIR7/kR8d/48eHP+NHRr/ixwZ/4gaGP+GGRf/hBgV//Ln5/////////////bw8P95Eg//dxAO/3UPDf9zDgz/GQMCb1EXFZ+vMS7/rS8s/6suK/+pLSr/piwp/9qpqP///////////////////////////+vU1P+VIh//kyAe/5EfHP+OHhv/jB0a/4obGf+IGhf/hhkW/4MXFf+BFhT/9Orq////////////+/n5/3cRD/90Dwz/cg0L/3AMCv8YAgJvUBYUn6wvLP+qLiv/qC0q/6YrKP+kKif/uV9d/////////////////////////////v7+/6hMSv+QHxz/jh0b/4scGv+JGxj/hxoX/4UYFv+DFxX/gBYT/4AYFv/8+fn////////////+/v7/dBAO/3ENC/9vDAn/bQoI/xcCAW9PFRSfqS0q/6csKf+lKyj/oyon/6EoJf+fKSb/8N/e////////////////////////////166t/40dGv+LHBn/iRoY/4YZF/+EGBX/ghcU/4AVE/9+FBL/jTMx//////////////////39/f9xDgz/bgsJ/2wKCP9qCQf/FwEBbzoPDommLCn/pCoo/6IpJv+gKCX/nick/5wlI/+9cW/////////////////////////////9+/v/nUA+/4gaF/+GGRb/gxgV/4EWFP9/FRP/fRQR/3sSEP+hWVf/////////////////8eno/24LCf9rCgf/aQgG/2IHBf8IAABVAAAAIWsbGuuhKSb/nygl/50mI/+bJSL/mSQh/5YjIP+5bm3/xIeG/8OGhf/ChoT/wIWE/7+Eg/+eR0X/hRgW/4MXFf+BFhP/fhUS/3wTEf96EhD/eBEO/4EkIv+naGb/rnZ1/7F8ev+eXVv/awkH/2gIBv9lBwX/MwMCzQAAAAn///8BAgAAIz8PDpdUFBOvUxQSr1ETEa9QEhGvTxIQr04RD69NEA+vTBAOr0oPDq9JDg2vSA4Mr0cNDK9GDAuvRQwKr0MLCa9CCgmvQQkIr0AJCK8/CAevPgcGrzwHBq87BgWvOgUErzkFBK84BAOvNgMCrx8BAYUAAAAR////AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
	$IMAGE_FOLDER="iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGrSURBVDjLxZO7ihRBFIa/6u0ZW7GHBUV0UQQTZzd3QdhMQxOfwMRXEANBMNQX0MzAzFAwEzHwARbNFDdwEd31Mj3X7a6uOr9BtzNjYjKBJ6nicP7v3KqcJFaxhBVtZUAK8OHlld2st7Xl3DJPVONP+zEUV4HqL5UDYHr5xvuQAjgl/Qs7TzvOOVAjxjlC+ePSwe6DfbVegLVuT4r14eTr6zvA8xSAoBLzx6pvj4l+DZIezuVkG9fY2H7YRQIMZIBwycmzH1/s3F8AapfIPNF3kQk7+kw9PWBy+IZOdg5Ug3mkAATy/t0usovzGeCUWTjCz0B+Sj0ekfdvkZ3abBv+U4GaCtJ1iEm6ANQJ6fEzrG/engcKw/wXQvEKxSEKQxRGKE7Izt+DSiwBJMUSm71rguMYhQKrBygOIRStf4TiFFRBvbRGKiQLWP29yRSHKBTtfdBmHs0BUpgvtgF4yRFR+NUKi0XZcYjCeCG2smkzLAHkbRBmP0/Uk26O5YnUActBp1GsAI+S5nRJJJal5K1aAMrq0d6Tm9uI6zjyf75dAe6tx/SsWeD//o2/Ab6IH3/h25pOAAAAAElFTkSuQmCC";
	$IMAGE_TITLE="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";
		
	switch ($_GET['getimg'])
    {
		case 'folder' :        
			header("Content-type: image/png");
			echo base64_decode($IMAGE_FOLDER);
        break;
		case 'title' :        
			header("Content-type: image/png");
			echo base64_decode($IMAGE_TITLE);
        break;
		case 'favicon' :        
			header("Content-type: image/x-icon");
			echo base64_decode($IMAGE_FAVICON);
        break;
	}
	
	exit();
}

?>

<html>
<head>
<title>UwAmp</title>
<link rel="shortcut icon" type="image/x-icon" href="./?getimg=favicon" /> 
<style type="text/css"> 
body
{
	position:relative;
	background-color: #FFFFFF;		
	font-family:"Trebuchet MS", Verdana;
	font-size: 10pt;
	text-align: left;
	margin: 0px;
	padding: 0px;
}

.mainblock
{
	padding:50px;
	border : solid 1px #DDDDDD;	
	background-color: #F5F5F5;
	width:798px;
	text-align:left;
}

a
{
	color: #014579;
	font-weight: bold;
	text-decoration: none;	
}

.afolder
{
	color: #014579;
	font-weight:bold;
	text-decoration: none;	
	background: url(./?getimg=folder) no-repeat left;
	padding-left:30px;
}

hr
{
	color: #DDDDDD;
	background-color: #DDDDDD;
	height: 1px;
	border: 0;
}

</style> 

</head>
<body>
<center>

<img src="./?getimg=title" />
<div class="mainblock">

<h2>Apache Work Fine!!!</h2>
<hr>
<h2>Configuration Setting</h2>
<li>Apache version : <?php echo $_SERVER['SERVER_SOFTWARE']; ?></li>
<li><a href="/mysql/">PHPMyAdmin</a></li>
<li><a href="/uwamp/phpinfo.php">PHP Info</a></li>
<br><br><hr>

<h2>Alias</h2>
<?php
$apacheconffile=$UWAMPFOLDER."bin/apache/conf/httpd.conf";
if (!file_exists ( $apacheconffile ))
{
	echo "Can't find Apache config file (httpd.conf)";
}
else
{
	$fp = fopen($apacheconffile,'r');
	$data = fread ($fp, filesize ($apacheconffile));
	fclose ($fp);	
	preg_match_all("/Alias[\\t ]*\"([^\"\']+)\"[\\t ]\"([^\"\']+)\"/i",$data,$matches,PREG_SET_ORDER);	
	$lists = array();
	foreach ($matches as $val)
	{
		if (!in_array($val, $lists))
		{
			$lists[] = $val;
			echo "<li><a class=\"afolder\" href=\"$val[1]\">$val[1]</a></li>";
		}	
	}
}

?>

<h2>Virtual Host</h2>
<?php

$handle=opendir($UWAMPFOLDER."www");
$count=0;
while ($file = readdir($handle)) 
{	
	if ($file=="." || $file=="..") continue;
	if (is_dir($UWAMPFOLDER."www/".$file))
	{		
		$count++;
		echo "<li><a class=\"afolder\" href=\"/$file\">$file</a></li>";
	}
}
closedir($handle);
if ($count==0)
{
	echo "No project found";
}
?>

<br><br>
<hr>
<center><a href="http://www.uwamp.com">UwAmp Home</a> - <a href="http://www.ubugtrack.com">uBugtrack</a></center>


</div>
</center>

</body>
</html>