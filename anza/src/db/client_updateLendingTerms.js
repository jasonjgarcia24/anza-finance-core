import axios from 'axios';
import config from '../config.json';

// 2.0.0 :: Update the loans proposal as approved.
export const updateApprovedLendingTerms = async (signedMessage, debtId) => {
	let response;

	try {
		response = axios.post(
			`http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/update/approve/lending_terms`,
			{ signedMessage: signedMessage, debtId: debtId.toString() }
		);
	} catch (err) {
		response = err.response;
	}

	return response;
};

// 2.0.1 :: Update the loan proposals to unallowed.
export const updateUnallowedLendingTerms = async (collateral) => {
	let response;

	try {
		response = axios.post(
			`http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/update/unallowed/lending_terms`,
			{ collateral: collateral }
		);
	} catch (err) {
		response = err.response;
	}

	return response;
};

// 2.0.2 :: Update the loan proposals to rejected.
export const updateRejectedLendingTerms = async (collateral) => {
	let response;

	try {
		response = axios.post(
			`http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/update/rejected/lending_terms`,
			{ collateral: collateral }
		);
	} catch (err) {
		response = err.response;
	}

	return response;
};