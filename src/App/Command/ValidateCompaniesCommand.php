<?php

declare(strict_types=1);

namespace App\App\Command;

use App\Core\Application\UseCase\ValidateCompanyFileUseCase;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'app:validate:companies',
    description: 'Valide les fichiers JSON contenant des entreprises et génère des logs succès/erreur.'
)]
final class ValidateCompaniesCommand extends Command
{
    public function __construct(
        private readonly ValidateCompanyFileUseCase $useCase,
        private readonly string $defaultDirectory = 'data/input'
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument(
                'path',
                InputArgument::OPTIONAL,
                'Chemin vers un fichier JSON ou un répertoire contenant des fichiers JSON',
                $this->defaultDirectory
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        /** @var string $path */
        $path = $input->getArgument('path');

        if (is_dir($path)) {
            $output->writeln(sprintf('<info>Scanning directory "%s"</info>', $path));

            $files = glob(rtrim($path, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . '*.json') ?: [];

            if ($files === []) {
                $output->writeln('<comment>Aucun fichier .json trouvé.</comment>');
                return Command::SUCCESS;
            }

            foreach ($files as $file) {
                $this->processFile($file, $output);
            }

            return Command::SUCCESS;
        }

        if (is_file($path)) {
            $this->processFile($path, $output);
            return Command::SUCCESS;
        }

        $output->writeln(sprintf('<error>Chemin "%s" introuvable</error>', $path));

        return Command::FAILURE;
    }

    private function processFile(string $file, OutputInterface $output): void
    {
        $output->writeln(sprintf('<info>Processing file: %s</info>', $file));

        try {
            $this->useCase->execute($file);
            $output->writeln('<info>✔ Logs générés.</info>');
        } catch (\Throwable $e) {
            $output->writeln(sprintf(
                '<error>Erreur lors du traitement du fichier "%s": %s</error>',
                $file,
                $e->getMessage()
            ));
        }
    }
}
