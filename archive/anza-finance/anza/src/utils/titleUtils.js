export const setPageTitle = (route) => {
    const pageTitle = document.getElementById('page-title').innerText;
    const baseTitle = pageTitle.split('\n')[0];
    document.getElementById('page-title').innerText = `${baseTitle}\n${route}`;
}