<?php

declare(strict_types=1);

use App\App\Command\ValidateCompaniesCommand;
use App\Core\Application\Ports\CompanyFileReaderInterface;
use App\Core\Application\Ports\CompanyValidationLoggerInterface;
use App\Infrastructure\FileSystem\JsonCompanyFileReader;
use App\Infrastructure\Logger\JsonFileCompanyValidationLogger;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return function (ContainerConfigurator $configurator): void {
    $services = $configurator->services()
        ->defaults()
        ->autowire()
        ->autoconfigure();

    // Autowire tout le code App\
    $services
        ->load('App\\', __DIR__ . '/../src/*');

    // Bind des interfaces vers les implémentations concrètes
    $services->set(CompanyFileReaderInterface::class, JsonCompanyFileReader::class);
    $services->set(CompanyValidationLoggerInterface::class, JsonFileCompanyValidationLogger::class);

    // Commande principale
    $services->set(ValidateCompaniesCommand::class)
        ->arg('$defaultDirectory', '%kernel.project_dir%/data/input')
        ->public();

    // Paramètre project_dir
    $configurator->parameters()
        ->set('kernel.project_dir', realpath(__DIR__ . '/..'));
};
