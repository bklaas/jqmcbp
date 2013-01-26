var teamsdb = new Object();
teamsdb["game_1"] = 
	{
		nextGame:"33",
		teams:['Illinois','Farleigh Dickinson']
	};
teamsdb["game_2"] =
	{
		nextGame:"33",
		teams:['Texas', 'Nevada']
	};
teamsdb["game_33"] =
	{	
		nextGame:"49",
		teams:['Illinois','Farleigh Dickinson','Texas','Nevada']
	};
teamsdb["game_49"] =
	{	
		nextGame:"57",
		teams:['Illinois','Farleigh Dickinson','Texas','Nevada']
	};

function advanceTeam(thisTeam,thisGame,nextGame)
{
	// change all teams in teamsdb for thisGame to done from select
	var TheseTeams = teamsdb[thisGame]["teams"];
	var ThoseTeams = teamsdb[nextGame]["teams"];
	for (var Team in TheseTeams) {
		var removeMe = document.getElementById(thisGame + " " + teamsdb[thisGame]["teams"][Team] + " select");
		var showMe = document.getElementById(thisGame + " " + teamsdb[thisGame]["teams"][Team] + " done");
		if (removeMe.style.display == 'block') {
			showMe.style.display = 'block';
		}
		removeMe.style.display = 'none';
	}
	// make thisTeam in thisGame emphasized
	var myPick = document.getElementById(thisGame + " " + thisTeam + " done");
	myPick.className = 'picked';
	// unselect all radios for nextGame
	//SetRadio(false, nextGame);
	// go through each team and if any are class = picked, display text only
	var displayType = " select";
	for (var Team in ThoseTeams) {
		var thisOne = document.getElementById(nextGame + " " + teamsdb[nextGame]["teams"][Team] + " done");
		if (thisOne.className == 'picked') {
			displayType = ' done';
		}
	}
	var nextOne = document.getElementById(nextGame + " " + thisTeam + displayType);
	nextOne.style.display = 'block';
}

function secondThoughts(team,thisGame,prevGame)
{
	// "display: none;" for team in thisGame
	var removeMe = document.getElementById(thisGame + " " + team + " select");
	removeMe.style.display = 'none';
	// remove text of teams in previous cell
	// unselect all radios for prevGame
	SetRadio(false, prevGame);
	// display radio buttons of only those teams that were displayed in text form
	var ThoseTeams = teamsdb[prevGame]["teams"];
	for (var Team in ThoseTeams) {
		var thisOne = document.getElementById(prevGame + " " + teamsdb[prevGame]["teams"][Team] + " done");
		var thatOne = document.getElementById(prevGame + " " + teamsdb[prevGame]["teams"][Team] + " select");
		if (thisOne.style.display == 'block') {
			thisOne.className = 'normal';
			thisOne.style.display = 'none';
			thatOne.style.display = 'block';
		}
	}
}

function DisableRadio(field) {
	var numelements = document.forms.bracketform.elements.length;
	for (var i=0 ; i<numelements ; i++) {
		item = document.forms.bracketform.elements[i];
		if (item.name == field) {
			item.disabled = true;
		}
	}
}

function SetRadio(value, field) {
	var numelements = document.forms.bracketform.elements.length;
	var item;
	for (var i=0 ; i<numelements ; i++) {
		item = document.forms.bracketform.elements[i];
		if (item.name == field) {
			item.checked = value;
		}
	}
}

