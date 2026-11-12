// The records page filter. A record matches when every field of the filter equals the record's field.
function applyFilter(records, filter) {
  return records.filter((r) => Object.entries(filter || {}).every(([key, value]) => r[key] === value));
}
module.exports = { applyFilter };
