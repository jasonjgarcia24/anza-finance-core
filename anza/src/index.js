import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Borrowing from './components/Borrowing/borrowing';
import Lending from './components/Lending/lending';
import Marketplace from './components/Marketplace/marketplace';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path='/' element={<App />}>
          <Route path='borrowing' element={<Borrowing />} />
          <Route path='lending' element={<Lending />} />
          <Route path='marketplace' element={<Marketplace />} />
          <Route
            path='*'
            element={
              <main style={{ padding: '1rem' }}>
                <p>😕 Site not found 😕</p>
              </main>
            }
          />
        </Route>
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);
