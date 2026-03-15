var winOptsPieGraph = 'resizeable=no,scrollbars=no,width=625,height=470';
var winOptsBig = 'resizeable=yes,scrollbars=yes,width=800,height=650';
var winOpts = 'resizeable=yes,scrollbars=yes,width=160,height=160';
var winOptsChew = 'resizeable=yes,scrollbars=yes,width=190,height=50';
var winOptsHF = 'resizeable=yes,scrollbars=yes,width=400,height=250';

function popUpAny(pPage,width,height) {
	var winOptsAny = 'resizeable=yes,scrollbars=yes,width='+width+',height='+height;
	popUpAnyGraph = window.open(pPage,'popWin',winOptsAny);
	popUpAnyGraph.focus();
}

function popUpPieGraph(pPage) {
 popUpWinPieGraph = window.open(pPage,'popWin',winOptsPieGraph);
 popUpWinPieGraph.focus();
 }


function popUpBig(pPage) {
 popUpWinBig = window.open(pPage,'popWin',winOptsBig);
 popUpWinBig.focus();
 }

function popUp(pPage) {
 popUpWin = window.open(pPage,'popWin',winOpts);
 popUpWin.focus();
 }

function popUpChew(pPage) {
 popUpWinChew = window.open(pPage,'popWin',winOptsChew);
 popUpWinChew.focus();
 }

function popUpHF(pPage) {
 popUpWinHF = window.open(pPage,'popWin',winOptsHF);
 popUpWinHF.focus();
 }

