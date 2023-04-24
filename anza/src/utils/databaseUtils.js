export const getLendingTermsPrimaryKey = (address, id) => {
    const _address = address.toLowerCase();
    const _id = id.toString().padStart(78, "0");

    return `${_address}_${_id}`;
}
