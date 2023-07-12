export const loanState = (terms) => {
    // 0x000000000000000000000000000000000000000000000000000000000000000F
    console.log(parseInt(terms.slice(-1, undefined), 16));
    return parseInt(terms.slice(-1, undefined), 16);
}

export const firInterval = (terms) => {
    // 0x00000000000000000000000000000000000000000000000000000000000000F0
    console.log(parseInt(terms.slice(-2, -1), 16));
    return parseInt(terms.slice(-2, -1), 16);
}

export const fixedInterestRate = (terms) => {
    // 0x000000000000000000000000000000000000000000000000000000000000FF00
    console.log(parseInt(terms.slice(-4, -2), 16));
    return parseInt(terms.slice(-4, -2), 16);
}

export const loanStart = (terms) => {
    // 0x0000000000000000000000000000000000000000000000000000FFFFFFFF0000
    console.log(parseInt(terms.slice(-12, -4), 16));
    return parseInt(terms.slice(-12, -4), 16);
}

export const loanDuration = (terms) => {
    // 0x00000000000000000000000000000000000000000000FFFFFFFF000000000000
    console.log(parseInt(terms.slice(-20, -12), 16));
    return parseInt(terms.slice(-20, -12), 16);
}

export const isFixed = (terms) => {
    // 0x0000000000000000000000000000000000000000000F00000000000000000000
    console.log(parseInt(terms.slice(-21, -20), 16));
    return parseInt(terms.slice(-21, -20), 16);
}

export const commital = (terms) => {
    // 0x00000000000000000000000000000000000000000FF000000000000000000000
    console.log(parseInt(terms.slice(-23, -21), 16));
    return parseInt(terms.slice(-23, -21), 16);
}

export const lenderRoyalties = (terms) => {
    // 0x00FF000000000000000000000000000000000000000000000000000000000000
    console.log(parseInt(terms.slice(4, 6), 16));
    return parseInt(terms.slice(4, 6), 16);
}

export const loanCount = (terms) => {
    // 0xFF00000000000000000000000000000000000000000000000000000000000000
    console.log(parseInt(terms.slice(2, 4), 16));
    return parseInt(terms.slice(2, 4), 16);
}
