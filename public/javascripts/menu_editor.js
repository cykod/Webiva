
function popupMenu(row_name,links) {
	var txt ='';
	var maxLength=12;
	for(var i=0;i<links.length;i++) {
		var internal = links[i];
		if(internal.length == 0) {
			txt += "<hr>";
		}
		else if(internal.length == 4) {
			if(internal[2] == 'js') {
				txt += "<a href='javascript:void(0);' onclick='cClick(); " + internal[3] + "'>" + internal[1] + "</a><br>";
			}
			else {
				txt += "<a href='" + internal[2] + "'onclick='nd(); return confirm(\"" + internal[3] + "\");' >"  + internal[1] + "</a><br>";
			}
			if(internal[1].length > maxLength)
				maxLength=internal[1].length;

		}
		else {
				txt += "<a href='" + internal[2] + "'>" + internal[1] + "</a><br>";
				if(internal[1].length > maxLength)
					maxLength=internal[1].length;
		}
	}

	//alert(maxLength);
	var width=30+maxLength * 7;

    performActionText = "Action"

	overlib(txt,CAPTION,"&nbsp;" + performActionText,STICKY,RIGHT,OFFSETX,0,OFFSETY,12,WIDTH,width,
				   FGCOLOR,'#FFFFFF',BGCOLOR,'#bababa');
}


function adjustHighlight() {
	if(highlight_level > 0 && highlight_level < (highlight_step.length-1)) {
		highlight_level++;
		document.getElementById(highlight_row).style.backgroundColor = highlight_step[highlight_level];
		JavaScript:setTimeout("adjustHighlight();", 50);
	}
}

function killHighlight() {
	if(highlight_row != '') {
		document.getElementById(highlight_row).style.backgroundColor = highlight_old;
		highlight_level = 0;
		highlight_row='';
	}
}


