import './App.css';
import { Outlet, Link } from 'react-router-dom';

const App = () => {
  return (
    <div className="App">
      <h1 id='page-title'>Anza Finance</h1>
      <nav>
        <Link className='link' to="/borrowing">Borrowing</Link> | {" "}
        <Link className='link' to="/lending">Lending</Link> | {" "}
        {/* <Link className='link' to="/borrowerloans">Loans</Link> | {" "}
        <Link className='link' to="/sponsoredLoans">Sponsored</Link> | {" "}
        <Link className='link' to="/refinanceLoans">Refinance</Link> */}
      </nav>
      <Outlet />
    </div>
  );
}

export default App;
