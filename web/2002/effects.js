<!-- Fade-in script by Bernhard Friedrich

document.bgcolor="#FFFFFF" 

var hexchars="0123456789ABCDEF";
function fromHex (str) {
var high=str.charAt(0); //Note: Netscape 2.0 bug workaround 


var low=str.charAt(1);
return(16*hexchars.indexOf(high))+hexchars.indexOf(low);
}

function Color(str){
	this.r=fromHex(str.substring(0,2));
	this.g=fromHex(str.substring(2,4));
	this.b=fromHex(str.substring(4,6));
	return this;
	}
col_value="#000000";
color_start=col_value.substring(1,8);
col_value="#FFFFFF"; 
color_end=col_value.substring(1,8);

function makearray(n) { 
    this.length = n; 
    for(var i = 1; i <= n; i++) 
        this[i] = 0; 
    return this;  
}

hexa = new makearray(16);
for(var i = 0; i < 10; i++)
    hexa[i] = i;
hexa[10]="a"; hexa[11]="b"; hexa[12]="c";
hexa[13]="d"; hexa[14]="e"; hexa[15]="f";

function hex(i) {
    if (i < 0)
        return "00";
    else if (i > 255)
        return "ff";
    else
        return "" + hexa[Math.floor(i/16)] + hexa[i%16];
}

function setbgColor(r, g, b) {
    var hr = hex(r); var hg = hex(g); var hb = hex(b);
    document.bgColor = "#"+hr+hg+hb;
}

function fade(sr, sg, sb, er, eg, eb, step) {
    for(var i = 0; i <= step; i++) {
        setbgColor(
        Math.floor(sr * ((step-i)/step) + er * (i/step)),
        Math.floor(sg * ((step-i)/step) + eg * (i/step)),
        Math.floor(sb * ((step-i)/step) + eb * (i/step)));
    }
}

function fadein() {
	fade(Color(color_start).r,Color(color_start).g,Color(color_start).b,Color(color_end).r,Color(color_end).g,Color(color_end).b,55); 
}

/* do fadein */
fadein();

/***** end fade script *****/
/************************************************************/
var winOptsPieGraph = 'resizeable=no,scrollbars=no,width=660,height=420';

function popUpPieGraph(pPage) {
 popUpWinPieGraph = window.open(pPage,'popWin',winOptsPieGraph);
 popUpWinPieGraph.focus();
 }

var winOptsBig = 'resizeable=yes,scrollbars=yes,width=600,height=500';

function popUpBig(pPage) {
 popUpWinBig = window.open(pPage,'popWin',winOptsBig);
 popUpWinBig.focus();
 }

var winOpts = 'resizeable=yes,scrollbars=yes,width=160,height=160';

function popUp(pPage) {
 popUpWin = window.open(pPage,'popWin',winOpts);
 popUpWin.focus();
 }

var winOptsChew = 'resizeable=yes,scrollbars=yes,width=190,height=50';

function popUpChew(pPage) {
 popUpWinChew = window.open(pPage,'popWin',winOptsChew);
 popUpWinChew.focus();
 }

// -->
