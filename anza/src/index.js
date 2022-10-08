import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Borrowing from './components/Borrowing/borrowing';
import Lending from './components/Lending/lending';
import BorrowerLoans from './components/Borrowing/borrowerLoans';
import LenderLoans from './components/Lending/sponsoredLoans';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path='/' element={<App />}>
          <Route path='borrowing' element={<Borrowing />} />
          <Route path='lending' element={<Lending />} />
          <Route path='borrowerLoans' element={<BorrowerLoans />} />
          <Route path='sponsoredLoans' element={<LenderLoans />} />
          <Route
            path='*'
            element={
              <main style={{ padding: '1rem' }}>
                <p>Site not found :(</p>
              </main>
            }
          />
        </Route>
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);
