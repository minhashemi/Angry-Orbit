% Angry Birds Space Simulation
% Jan 2023, Sharif University of Technology
% Amin Hashemi - @minhashemi (Github)


function [struct,realTime] =  AngryBirdsDriverLittleG
close all

BirdData = textread('GameData-Tracker.txt');

%constants
    Planet1 = [24.86, -.656];     %location of first planet

    x1 = Planet1(1);
    y1 = Planet1(2);
    R1 = 5.688/2;                   %radius of first planet
    fR1 = 28.99/2;                  %atmosphere of first planet
    Planet2 = [52.7, -.656];      %location of second planet
    x2 = Planet2(1);
    y2 = Planet2(2);
    R2 = 5.688/2;                   %radius of second planet
    fR2 = 34.15/2;                  %atmosphere of second planet
    
    %[xpos,vx,ypos,vy] of angry bird
    RedBird = [BirdData(1,2), BirdData(1,4),BirdData(1,3), BirdData(1,5)];
    
    xb0 = RedBird(1);
    vxb0 = RedBird(2);
    yb0 = RedBird(3); 
    vyb0 = RedBird(4);    
    mBird = 1;                      %mass of a red bird
    g1 = 20;
    g2 = 20;
    
    for k = 2.5
    
    constants = [x1, y1, x2, y2, g1, g2, k, mBird, fR1, fR2, R1, R2];

    %characteristic length and time
      xc = x1;
      tau = sqrt(x1/g1);

%solve the coupled ODEs
    %specify the initial position and speed in unitless terms
    init = [xb0./x1, vxb0./(x1/tau), yb0./x1, vyb0./(x1/tau)]; 
    endTime = BirdData(end,1);
    tSpan = [0 endTime/(tau)];%convert desired time into unitless time

    options = odeset('Events', @eventsCollisionDetection);

    struct = ode23(@fAngryBirdDiffEQ, tSpan, init, options,constants);

    %catch unitless output 
        ut = struct.x;       %struct.x is unitless time T
        ux = struct.y(1,:);   
        %uvx = struct.y(2,:);
        uy = struct.y(3,:);
        %uvy = struct.y(4,:);

    
             realTime = ut*tau;
      
      %Shifting BirdData to t = 0
      BirdData(:,1) = BirdData(:,1) - BirdData(1,1);
             
             
    %plot real variables
    realX = ux*xc;
    realY = uy*xc;
    %positions in space
        %define coordinates for gravitational circles and
        %planet circles
        N = 256;
        theta = (0:N)*2*pi/N;
        %Note: using the same radius for both gravity
        %atmospheres and planets
        x = fR1*cos(theta) + x1;
        xn = fR2*cos(theta) + x2;
        y = fR1*sin(theta) + y1;
        yn = fR2*sin(theta) + y2;
        xA = R1*cos(theta) + x1;
        yA = R1*sin(theta) + y1;

    %plot(realX,realY,'r-',x1,y1,'kx',x2,y2,'kx')
    figure
    hold on
    plot(realX,realY,'r--',x1,y1,'kx',x2,y2,'kx',x,y,'b-',xn, ...
        yn,'b-',xA,yA,'k', xA+(x2-x1),yA + (y2-y1), 'k', BirdData(:,2),BirdData(:,3),'c')
    plot(zeros(1,70), 'g')
    %axis([0 80 -40 40])
    xlabel('real x')
    ylabel('real y')
    title(strcat('k =',num2str(k),'g_{1}=',num2str(g1),'g_{2}=',...
        num2str(g2)));
    hold off
    
    
    
    
    
      
    end
end

function vPrime = fAngryBirdDiffEQ(~, v, constants)
%constants
    x1 = constants(1);
    y1 = constants(2);
    x2 = constants(3);
    y2 = constants(4);
    g1 = constants(5);
    g2 = constants(6);
    k  = constants(7);
    mBird = constants(8);
    fR1 = constants(9);
    fR2 = constants(10);
        
   A = 1;       %boolean coefficient for first planet
   B = 1;       %boolean coefficient for second planet
   C = 0;       %boolean drag coefficient to turn on drag when inside either atmosphere
    
%initialize vPrime
    vPrime = zeros(4,1);
    
%If the bird is outside of either planet atmosphere, remove the effects of
%that planet atmosphere
    if fR1^2 < (v(1)*x1 - x1)^2 + (v(3)*x1 - y1)^2   %outside asteriod1 atmosphere
        A = 0;
    end
    
    if fR2^2 < (v(1)*x1 - x2)^2 + (v(3)*x1 - y2)^2   %outside asteriod2 atmosphere
        B = 0;
    end

%If the bird is inside either planet atmosphere, include drag
   if (A == 1 || B == 1 )
       C = 1;
   end
    
    %differential equations of motion
    vPrime(1) = v(2);
    vPrime(2) = A*(1-v(1))./sqrt((1-v(1)).^2 + ((y1/x1)-v(3)).^2)...
                + B*(g2/g1)*(x2/x1 - v(1))./sqrt(((x2/x1)-v(1)).^2 + ...
                ((y2/x1)-v(3)).^2)...
                - C*k/(g1*mBird) * v(2)./sqrt(v(2).^2 + v(4).^2);
    vPrime(3) = v(4);
    vPrime(4) = A*((y1/x1)-v(3))./sqrt((1-v(1)).^2 + ((y1/x1)-v(3)).^2)...
                + B*(g2/g1)*(y2/x1 - v(3))./sqrt(((x2/x1)-v(1)).^2 + ...
                ((y2/x1)-v(3)).^2)...
                - C*k/(g1*mBird) * v(4)./sqrt(v(2).^2 + v(4).^2);
            
end



%determines if bird has collided with an planet, if so, terminates
%the ode solver    
function [value,isTerminal,dir] = eventsCollisionDetection(~,v,constants)

    %acquire all of the constants needed for this function
    x1 = constants(1);
    y1 = constants(2);
    x2 = constants(3);
    y2 = constants(4);
    R1 = constants(11);
    R2 = constants(12);
    
    %define the variables if neither if statement is true
    value = 1;
    isTerminal = 0;
    dir = 0;
    
     if R1^2 > (v(1)*x1 - x1)^2 + (v(3)*x1 - y1)^2%bird is inside asteriod1
        value = 0;
        isTerminal = 1;
        dir = 0;
     end
    
     if R2^2 > (v(1)*x1 - x2)^2 + (v(3)*x1 - y2)^2%bird is inside asteriod2
        value = 0;
        isTerminal = 1;
        dir = 0;
     end
end

 