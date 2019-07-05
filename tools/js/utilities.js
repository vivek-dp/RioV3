
function createParamString(params) {
    str = "";
    str += "@"+params.join("@");
    return str;
}

function createBeam() {
    window.location.href = 'skp:create_beam@';
    //sketchup.rioCreateRoom(10, 22);
}//Create room 

function addPerimeterWall() {
    window.location.href = 'skp:add_perimeter_wall';
}

function removePerimeterWall() {
    window.location.href = 'skp:remove_perimeter_wall';
}
