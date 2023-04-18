import axios from 'axios';
import config from '../config.json';

// 1.0.0 :: Update the loans proposal as approved.
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

// 1.1.0 :: Update the loan proposals with matching collateral to unallowed.
export const updateUnallowedCollateralLendingTerms = async (collateral) => {
	let response;

	try {
		response = axios.post(
			`http://${config.SERVER.HOST}:${config.SERVER.PORT}/api/update/collateral_unallowed/lending_terms`,
			{ collateral: collateral }
		);
	} catch (err) {
		response = err.response;
	}

	return response;
};