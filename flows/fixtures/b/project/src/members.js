const members = [];
function addMember(name, email) { members.push({ name, email, joined: new Date().toISOString() }); }
function listMembers() { return members; }
module.exports = { addMember, listMembers };
