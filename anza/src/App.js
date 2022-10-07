import './App.css';
import { Outlet, Link } from 'react-router-dom';

const App = () => {
  return (
    <div className="App">
      <h1 id='page-title'>NFT Finance App</h1>
      <nav>
        <Link className='link' to="/borrowing">Borrowing</Link> | {" "}
        <Link className='link' to="/lending">Lending</Link>
      </nav>
      <Outlet />
    </div>
  );
}

export default App;
