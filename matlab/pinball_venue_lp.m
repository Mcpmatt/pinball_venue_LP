%% ============================================================
%% Pinball Venue Floor Space Optimization
%% Linear Programming Model
%% Math 481: Optimization
%%
%% Objective: Maximize annual gross revenue by optimally
%% allocating square footage across four venue zones given
%% a fixed 3,500 sq ft location.
%%
%% Decision Variables:
%%   x(1) = sq ft allocated to FreePlay floor
%%   x(2) = sq ft allocated to Premium room
%%   x(3) = sq ft allocated to Private bays
%%   x(4) = sq ft allocated to Bar + entry + bathrooms
%% ============================================================
 
clc; clear; close all;
 
%% ── PARAMETERS ───────────────────────────────────────────────
S_total = 3500;             % Total venue sq ft
S_eff   = (S_total/1.12) - 320; % Net allocatable space (~2,805 sq ft)
                            % 12% circulation factor + 320 sq ft back of house
 
V  = 40;                    % Average daily visitors
d  = 364;                   % Operating days per year
e  = 12.50;                 % Average entry fee ($)
p  = 8.00;                  % Blended premium spend per visitor ($)
br = 12.00;                 % Average bar spend per visitor ($)
u  = 0.50;                  % Bay utilization rate
r  = 95;                    % Average bay booking rate ($)
w  = 3.5;                   % Max bookings per bay per week
 
%% ── REVENUE COEFFICIENTS ($ per sq ft per year) ──────────────
% Each coefficient = annual zone revenue / baseline zone sq ft
% Baseline sq ft derived from machine count x 65 sq ft per machine
% (65 sq ft reflects premium spacing standard vs. 50 sq ft arcade standard)
 
c1 = (V * e  * d) / (15 * 65);          % FreePlay : $186.67/sq ft
c2 = (V * p  * d) / ( 6 * 65);          % Premium  : $298.67/sq ft
c3 = ((r * w*u*52) + (28*w*u*52)) / 220;% Bays     :  $50.88/sq ft
c4 = (V * br * d) / 550;                % Bar      : $317.67/sq ft
 
fprintf('Revenue coefficients ($/sq ft/year):\n');
fprintf('  FreePlay  (c1): $%.2f\n', c1);
fprintf('  Premium   (c2): $%.2f\n', c2);
fprintf('  Bays      (c3): $%.2f\n', c3);
fprintf('  Bar       (c4): $%.2f\n\n', c4);
 
%% ── LP FORMULATION ───────────────────────────────────────────
% Maximize Z = c1*x1 + c2*x2 + c3*x3 + c4*x4
% linprog minimizes by default — negate objective to maximize
 
f = -[c1; c2; c3; c4];
 
% Inequality constraint: x1 + x2 + x3 + x4 <= S_eff
A   = [1 1 1 1];
b_c = S_eff;
 
% No equality constraints
Aeq = []; beq = [];
 
% Lower bounds: minimum viable zone allocations
lb = [650;   % FreePlay  >= 10 machines x 65 sq ft
      260;   % Premium   >=  4 machines x 65 sq ft
        0;   % Bays      >=  0 (optional at launch)
      400];  % Bar       >= 400 sq ft functional minimum
 
% Upper bounds: maximum zone allocations
ub = [975;   % FreePlay  <= 15 machines x 65 sq ft
      520;   % Premium   <=  8 machines x 65 sq ft
     1760;   % Bays      <=  8 bays x 220 sq ft
      700];  % Bar       <= 700 sq ft
 
%% ── SOLVE ────────────────────────────────────────────────────
options = optimoptions('linprog', 'Display', 'none');
[x_opt, fval, exitflag] = linprog(f, A, b_c, Aeq, beq, lb, ub, options);
 
if exitflag ~= 1
    fprintf('Warning: solver did not converge cleanly (exit flag: %d)\n', exitflag);
end
 
Z_opt = -fval;
 
%% ── RESULTS ──────────────────────────────────────────────────
fprintf('===========================================\n');
fprintf('           OPTIMAL SOLUTION\n');
fprintf('===========================================\n');
fprintf('FreePlay floor : %6.1f sq ft  (%d machines)\n', x_opt(1), round(x_opt(1)/65));
fprintf('Premium room   : %6.1f sq ft  (%d machines)\n', x_opt(2), round(x_opt(2)/65));
fprintf('Private bays   : %6.1f sq ft  (%d bays)\n',     x_opt(3), round(x_opt(3)/220));
fprintf('Bar + entry    : %6.1f sq ft\n',                 x_opt(4));
fprintf('Back of house  :  320.0 sq ft  (fixed)\n');
fprintf('-------------------------------------------\n');
fprintf('Total allocated: %6.1f sq ft\n', sum(x_opt) + 320);
fprintf('-------------------------------------------\n');
fprintf('Optimal Annual Revenue: $%.0f\n', Z_opt);
fprintf('===========================================\n\n');
 
fprintf('Revenue breakdown:\n');
fprintf('  Entry fees (FreePlay) : $%.0f  (%.1f%%)\n', c1*x_opt(1), 100*c1*x_opt(1)/Z_opt);
fprintf('  Premium play          : $%.0f  (%.1f%%)\n', c2*x_opt(2), 100*c2*x_opt(2)/Z_opt);
fprintf('  Private bays          : $%.0f   (%.1f%%)\n', c3*x_opt(3), 100*c3*x_opt(3)/Z_opt);
fprintf('  Bar / beverage        : $%.0f  (%.1f%%)\n', c4*x_opt(4), 100*c4*x_opt(4)/Z_opt);
fprintf('  -----------------------------------\n');
fprintf('  Total                 : $%.0f\n\n', Z_opt);
 
%% ── FEASIBLE REGION PLOT ─────────────────────────────────────
% 2D slice: x1 (FreePlay) vs x2 (Premium)
% x3 and x4 fixed at optimal values to isolate the binding constraints
% on the two most directly comparable decision variables
 
x3_fixed  = x_opt(3);
x4_fixed  = x_opt(4);
remaining = S_eff - x3_fixed - x4_fixed;
 
figure('Name', 'Pinball Venue LP — Feasible Region', ...
       'Position', [100 100 860 640]);
 
% Shade feasible region
x1_range = linspace(650, 975, 400);
x2_upper = min(520, remaining - x1_range);
x2_lower = 260 * ones(size(x1_range));
feasible = x2_upper >= x2_lower;
 
fill([x1_range(feasible), fliplr(x1_range(feasible))], ...
     [x2_upper(feasible), fliplr(x2_lower(feasible))], ...
     [0.85 0.92 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;
 
x1_plot = linspace(580, 1020, 400);
 
% Space constraint
plot(x1_plot, remaining - x1_plot, 'b-', 'LineWidth', 2, ...
     'DisplayName', sprintf('Space: x_1+x_2 \\leq %.0f sq ft', remaining));
 
% FreePlay bounds
plot([650 650], [180 580], 'r--', 'LineWidth', 1.5, ...
     'DisplayName', 'Min FreePlay (650 sq ft)');
plot([975 975], [180 580], 'r-',  'LineWidth', 1.5, ...
     'DisplayName', 'Max FreePlay (975 sq ft)');
 
% Premium bounds
plot([580 1020], [260 260], 'm--', 'LineWidth', 1.5, ...
     'DisplayName', 'Min Premium (260 sq ft)');
plot([580 1020], [520 520], 'm-',  'LineWidth', 1.5, ...
     'DisplayName', 'Max Premium (520 sq ft)');
 
% Iso-revenue contour lines
Z_levels  = [350000, 450000, 520000, round(Z_opt)];
iso_colors = [0.75 0.75 0.75;
              0.55 0.55 0.55;
              0.30 0.30 0.30;
              0.05 0.45 0.05];
x1_cont = linspace(580, 1020, 400);
for i = 1:length(Z_levels)
    x2_cont = (Z_levels(i) - c1*x1_cont - c3*x3_fixed - c4*x4_fixed) / c2;
    plot(x1_cont, x2_cont, '--', 'Color', iso_colors(i,:), 'LineWidth', 1.2, ...
         'DisplayName', sprintf('Z = $%.0f', Z_levels(i)));
end
 
% Optimal point
plot(x_opt(1), x_opt(2), 'k*', 'MarkerSize', 14, 'LineWidth', 2, ...
     'DisplayName', sprintf('Optimal (%.0f, %.0f)', x_opt(1), x_opt(2)));
 
% Annotation
ann = sprintf(['  Optimal Solution\n' ...
               '  x_1 = %.0f sq ft (%d machines)\n' ...
               '  x_2 = %.0f sq ft (%d machines)\n' ...
               '  x_3 = %.0f sq ft (%d bays)\n'     ...
               '  x_4 = %.0f sq ft (bar)\n'          ...
               '  Z   = $%.0f/year'], ...
    x_opt(1), round(x_opt(1)/65), ...
    x_opt(2), round(x_opt(2)/65), ...
    x_opt(3), round(x_opt(3)/220), ...
    x_opt(4), Z_opt);
text(x_opt(1)-355, x_opt(2)-55, ann, ...
     'FontSize', 8.5, 'BackgroundColor', 'white', ...
     'EdgeColor', [0.3 0.3 0.3], 'Margin', 5, ...
     'VerticalAlignment', 'top');
 
xlabel('x_1 — FreePlay Floor (sq ft)', 'FontSize', 13);
ylabel('x_2 — Premium Room (sq ft)',   'FontSize', 13);
title({'Pinball Venue LP — Feasible Region', ...
       'FreePlay vs. Premium Allocation (Bays and Bar at optimal values)'}, ...
      'FontSize', 12, 'FontWeight', 'bold');
legend('Feasible region', 'Space constraint', ...
       'Min FreePlay', 'Max FreePlay', ...
       'Min Premium',  'Max Premium', ...
       'Z = $350,000', 'Z = $450,000', 'Z = $520,000', ...
       sprintf('Z = $%.0f (optimal)', Z_opt), ...
       'Optimal solution', ...
       'Location', 'northeast', 'FontSize', 9);
xlim([580 1020]); ylim([180 580]);
grid on;
ax = gca; ax.GridAlpha = 0.25;
hold off;
 
fprintf('Figure generated: Feasible region — FreePlay vs. Premium allocation\n');
