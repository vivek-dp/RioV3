
function createParamString(params) {
    str = "";
    str += "@"+params.join("@");
    return str;
}

function createBeam() {
    window.location.href = 'skp:createBeam@';
    //sketchup.rioCreateRoom(10, 22);
}//Create room 

