$( document ).ready(function() {

	var Times = new Array();
	var Dates = new Array();

	Times = ["8:30","9:30","10:30","11:30","12:30","13:30","14:30","15:30"];
	Dates = ["01/21/14","01/22/14","01/23/14","01/24/14"];

	var HEIGHT = 50;
	var WIDTH = 50;
	var LABELWIDTH = 90;

	for(var j = 0; j < 5; j++) {
		for(var i = 0; i < 9; i++) {
			if (i==0 && j==0) { //CORNER SQUARE
				$("div.grid").append("<div class='corner' style='left:" + i*LABELWIDTH + "px; top:" + j*HEIGHT + "px;'>&nbsp;</div>");
			}
			else if (j==0) { //TIMES ROW
				$("div.grid").append("<div class='timelabel' style='left:" + i*WIDTH + "px; top:" + j*HEIGHT + "px;'>" + Times[i-1] + "</div>");
			}
			else if (i==0) { //DATES COLUMN
				$("div.grid").append("<div class='datelabel' style='left:" + i*LABELWIDTH + "px; top:" + j*HEIGHT + "px;'>" + Dates[j-1] + "</div>");
			}
			else { //ALL ACTIVE SQUARES
				$("div.grid").append("<div class='square' style='left:" + i*WIDTH + "px; top:" + j*HEIGHT + "px;'>&nbsp;</div>");
			}
		}
	}

	// function gridStructure() {
	// 	function hitData() {
	// 		this.discovered = false;
	// 		this.ship_name = "";
	// 	}

	// 	var grid_structure = new Array(10);

	// 	for (i = 0; i < 10; i++) {
	// 		grid_structure[i] = new Array(10);
	// 		for (j = 0; j < 10; j++) {
	// 			grid_structure[i][j] = new hitData();
	// 		}
	// 	}
	// }


	//$(".square").click(function(event) {
	
	//	var row = Number(this.id.charAt(length));
	//	var column = Number(this.id.charAt(length+1));
	//	alert(row + "" + column);

	//});

});