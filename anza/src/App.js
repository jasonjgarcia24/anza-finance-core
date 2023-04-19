import './App.css';
import { Outlet, Link } from 'react-router-dom';

const App = () => {
  return (
    <div className="App main-div">
      <div >
        <h1 id='page-title'>Anza Finance</h1>
        <nav>
          <Link className='link' to="/about">About</Link> | {" "}
          <Link className='link' to="/borrowing">Borrowing</Link> | {" "}
          <Link className='link' to="/lending">Lending</Link> | {" "}
          <Link className='link' to="/marketplace">Marketplace</Link>
        </nav>
      </div>
      <Outlet />
    </div>
  );
}

export default App;
