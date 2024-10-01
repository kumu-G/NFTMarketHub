import MainMenu from '@components/MainMenu';
import React, { ReactNode } from 'react';

interface LayoutProps {
    children: ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
    return (
        <div>
            <MainMenu />
            <hr />
            {children}
        </div>
    );
}

export default Layout;
